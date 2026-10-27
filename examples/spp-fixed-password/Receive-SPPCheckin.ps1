#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param([string]$ConfigPath=(Join-Path $PSScriptRoot 'config.json'),[switch]$NoTaskLaunch,[int]$StopAfterSeconds=0)
if (!$PSCmdlet.ShouldProcess($ConfigPath, 'Listen for syslog, write queue and dispatch worker')) { return }
if (!$IsWindows) { throw 'This deployment requires Windows and DPAPI.' }
. (Join-Path $PSScriptRoot 'Common.ps1')
. (Join-Path $PSScriptRoot 'Receiver.Core.ps1')
Read-Configuration $ConfigPath
$lock=$null;$listener=$null;$clients=[Collections.Generic.List[object]]::new()
try {
    $lock=[IO.File]::Open((Join-Path $Runtime 'receiver.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    if(!(Test-Path (Join-Path $Runtime 'checkin-state.json')) -and !$NoTaskLaunch){throw 'Initialize the worker state first.'}
    $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Parse($Config.ListenAddress),$Config.Port)
    $listener.Start()
    Write-Log 'receiver' "Listening on $($Config.ListenAddress):$($Config.Port); TCP JSON syslog."
    # Reconcile audit events once on startup/restart to cover receiver downtime.
    if(!$NoTaskLaunch){Write-AtomicJson (Join-Path $Runtime ('queue/startup-'+[guid]::NewGuid().ToString('N')+'.json')) @{Kind='Reconcile';ReceivedUtc=[DateTime]::UtcNow.ToString('o')}}
    $started=[DateTime]::UtcNow;$lastLaunch=[DateTime]::MinValue
    while($true) {
        if($StopAfterSeconds -gt 0 -and ([DateTime]::UtcNow-$started).TotalSeconds -ge $StopAfterSeconds){break}
        while($listener.Pending()) {
            $tcp=$listener.AcceptTcpClient();$remote=$tcp.Client.RemoteEndPoint.Address.ToString()
            if($remote -notin $Config.AllowedSources -or $clients.Count -ge 16){$tcp.Dispose();continue}
            $clients.Add(@{Client=$tcp;Stream=$tcp.GetStream();Buffer=[Collections.Generic.List[byte]]::new();LastRead=[DateTime]::UtcNow})
        }
        for($i=$clients.Count-1;$i -ge 0;$i--) {
            $client=$clients[$i]
            try {
                if($client.Client.Client.Poll(0,[Net.Sockets.SelectMode]::SelectRead) -and $client.Client.Available -eq 0){throw 'Connection closed'}
                if($client.Stream.DataAvailable) {
                    $bytes=[byte[]]::new(8192);$count=$client.Stream.Read($bytes,0,$bytes.Length)
                    if($count -eq 0){throw 'Connection closed'}
                    $client.Buffer.AddRange([byte[]]$bytes[0..($count-1)]);$client.LastRead=[DateTime]::UtcNow
                    foreach($message in @(Read-SyslogFrames $client.Buffer)) {
                        $event=Convert-CheckinMessage $message $Config.AccountId $Config.AssetId
                        if($null -eq $event){Write-Log 'receiver' 'Ignored frame: not a matching flat JSON check-in event. Check JSON format / empty KeyPrefix if a real target event was expected.';continue}
                        $key=Get-QueueKey $event.RequestId
                        $file=Join-Path $Runtime "queue/$key.json"
                        if(!(Test-Path -LiteralPath $file)) {
                            Write-AtomicJson $file @{Kind='Checkin';RequestId=$event.RequestId;ReceivedUtc=[DateTime]::UtcNow.ToString('o')}
                            Write-Log 'receiver' "Queued check-in request $($event.RequestId)."
                        }
                    }
                }
                if(([DateTime]::UtcNow-$client.LastRead).TotalMinutes -gt 5){throw 'Idle connection closed'}
            } catch {
                Write-Log 'receiver' 'TCP connection closed or invalid frame rejected.'
                $client.Client.Dispose();$clients.RemoveAt($i)
            }
        }
        if(!$NoTaskLaunch -and !(Test-Path (Join-Path $Runtime 'blocked.json')) -and ([DateTime]::UtcNow-$lastLaunch).TotalSeconds -ge 10) {
            if(@(Get-ChildItem (Join-Path $Runtime 'queue') -Filter '*.json').Count) {
                # The task name comes only from the local protected configuration.
                try {
                    $task=Get-ScheduledTask -TaskName $Config.WorkerTaskName -ErrorAction Stop
                    if([string]$task.State -notin @('Running','4','Queued','2')){Start-ScheduledTask -InputObject $task -ErrorAction Stop;Write-Log 'receiver' 'Worker task requested.'}
                } catch {Write-Log 'receiver' 'Unable to start worker task; queued messages retained.'}
                $lastLaunch=[DateTime]::UtcNow
            }
        }
        Start-Sleep -Milliseconds 100
    }
} catch {Write-Log 'receiver' 'Receiver stopped with an error. Check configuration, state initialization, port binding and task history.';throw}
finally {
    foreach($client in $clients){$client.Client.Dispose()}
    if($listener){$listener.Stop()}
    if($lock){$lock.Dispose()}
}
