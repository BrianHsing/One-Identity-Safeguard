#requires -Version 7.0
#requires -RunAsAdministrator
# Installer revision 1.3: handle textual and numeric Windows CIM enum values.
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param([string]$ConfigPath=(Join-Path $PSScriptRoot 'config.json'),[pscredential]$WindowsCredential,[switch]$SkipFirewallConfiguration)
if (!$PSCmdlet.ShouldProcess($ConfigPath, 'Set ACL, register tasks, configure firewall and start listener')) { return }
if (!$IsWindows) { throw 'This deployment requires Windows and DPAPI.' }
. (Join-Path $PSScriptRoot 'Common.ps1')
Read-Configuration $ConfigPath
$ConfigPath=(Resolve-Path -LiteralPath $ConfigPath).Path
if(!(Test-Path (Join-Path $Runtime 'checkin-state.json'))){throw 'Initialize the worker under the scheduled Windows user first.'}
if(!(Test-Path $CredentialPath)){throw 'SPP credential file not found.'}
if($Root.Contains('"')){throw 'Unsupported directory name.'}
if(!$WindowsCredential){$WindowsCredential=Get-Credential -UserName ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -Message 'Windows account password (NOT SPP password or Windows Hello PIN)' -ErrorAction Stop}
if(!$WindowsCredential){throw 'Windows credential is required.'}
$sid=([Security.Principal.NTAccount]::new($WindowsCredential.UserName)).Translate([Security.Principal.SecurityIdentifier])
$currentSid=[Security.Principal.WindowsIdentity]::GetCurrent().User
if($sid -ne $currentSid){throw 'Run installation under the same Windows user that exported the SPP credential. Different execution users require re-exporting credentials and separate ACL configuration.'}
$pwsh=Join-Path $PSHOME 'pwsh.exe'
$savedCredential=Import-Clixml -LiteralPath $CredentialPath -ErrorAction Stop
if($savedCredential -isnot [pscredential]){throw 'Invalid SPP credential file.'}
$savedCredential=$null
$fixedCredential=Import-Clixml -LiteralPath (Join-Path $Root 'fixed-password.xml') -ErrorAction Stop
if($fixedCredential -isnot [pscredential]){throw 'Invalid fixed-password credential file.'}
$fixedCredential=$null
function Assert-ExistingTask {
    param($Task,$Action,[string]$Description,[bool]$Listener)
    $actions=@($Task.Actions)
    $taskUser=$Task.Principal.UserId
    $taskSid=if($taskUser -match '^S-1-'){$taskUser}else{([Security.Principal.NTAccount]::new($taskUser)).Translate([Security.Principal.SecurityIdentifier]).Value}
    if($actions.Count -ne 1 -or $actions[0].Execute -ne $Action.Execute -or $actions[0].Arguments -cne $Action.Arguments -or
       $actions[0].WorkingDirectory -ne $Root -or $Task.Description -cne $Description -or
       $taskSid -ne $currentSid.Value -or [string]$Task.Principal.LogonType -notin @('Password','1') -or
       [string]$Task.Settings.Enabled -notin @('True','1') -or [string]$Task.Settings.MultipleInstances -notin @('IgnoreNew','2')) {
        throw "Existing task differs: $($Task.TaskName). It will not be overwritten."
    }
    $triggers=@($Task.Triggers | Where-Object {$null -ne $_})
    if($Listener) {
        if($triggers.Count -ne 1 -or $triggers[0].CimClass.CimClassName -ne 'MSFT_TaskBootTrigger' -or [string]$triggers[0].Enabled -notin @('True','1') -or $Task.Settings.ExecutionTimeLimit -ne 'PT0S') {
            throw 'Existing listener trigger or execution limit differs.'
        }
    } elseif($triggers.Count -ne 0 -or $Task.Settings.ExecutionTimeLimit -ne 'PT1H'){throw 'Existing worker must be on-demand only with a one-hour limit.'}
}
function Assert-ExistingFirewall {
    param($Rule)
    $ports=@($Rule | Get-NetFirewallPortFilter -ErrorAction Stop)
    $addresses=@($Rule | Get-NetFirewallAddressFilter -ErrorAction Stop)
    $applications=@($Rule | Get-NetFirewallApplicationFilter -ErrorAction Stop)
    if($ports.Count -ne 1 -or $addresses.Count -ne 1 -or $applications.Count -ne 1){throw 'Ambiguous firewall filters.'}
    $expected=@($Config.AllowedSources | Sort-Object -Unique)
    $actual=@($addresses[0].RemoteAddress | ForEach-Object {$_ -replace '/32$',''} | Sort-Object -Unique)
    $program=[Environment]::ExpandEnvironmentVariables($applications[0].Program).Trim('"')
    if([string]$Rule.Enabled -notin @('True','1') -or [string]$Rule.Direction -notin @('Inbound','1') -or [string]$Rule.Action -notin @('Allow','2') -or
       [string]$Rule.Profile -notin @('Any','0') -or [string]$ports[0].Protocol -notin @('TCP','6') -or
       [string]$ports[0].LocalPort -ne [string]$Config.Port -or $program -ne $pwsh -or
       ($expected -join ',') -ne ($actual -join ',')){
        $details=[ordered]@{Enabled=[string]$Rule.Enabled;Direction=[string]$Rule.Direction;Action=[string]$Rule.Action;Profile=[string]$Rule.Profile;
            Protocol=[string]$ports[0].Protocol;LocalPort=[string]$ports[0].LocalPort;ExpectedPort=[string]$Config.Port;
            Program=$program;ExpectedProgram=$pwsh;RemoteAddresses=$actual;ExpectedRemoteAddresses=$expected}
        throw ('Existing firewall differs; no rule was changed. Details: '+($details|ConvertTo-Json -Compress))
    }
}
$firewallName='SPP-CheckinPush-TCP-'+$Config.Port
$existingFirewall=@()
if(!$SkipFirewallConfiguration) {
    $existingFirewall=@(Get-NetFirewallRule -PolicyStore PersistentStore -ErrorAction Stop | Where-Object {$_.Name -eq $firewallName})
    if($existingFirewall.Count -gt 1){throw 'Ambiguous firewall rule name.'}
    if($existingFirewall.Count){Assert-ExistingFirewall $existingFirewall[0]}
} else {Write-Host 'Firewall configuration is externally managed: no firewall rules will be read or changed.'}
# Restrict scripts, durable state and credentials to this user, Administrators and SYSTEM.
$acl=[Security.AccessControl.DirectorySecurity]::new()
$acl.SetAccessRuleProtection($true,$false)
foreach($identity in @($sid,[Security.Principal.SecurityIdentifier]::new('S-1-5-18'),[Security.Principal.SecurityIdentifier]::new('S-1-5-32-544'))) {
    $rule=[Security.AccessControl.FileSystemAccessRule]::new($identity,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
    $acl.AddAccessRule($rule)
}
$listenerAction=New-ScheduledTaskAction -Execute $pwsh -Argument "-NoProfile -NonInteractive -File `"$(Join-Path $Root 'Receive-SPPCheckin.ps1')`" -ConfigPath `"$ConfigPath`"" -WorkingDirectory $Root -ErrorAction Stop
$workerAction=New-ScheduledTaskAction -Execute $pwsh -Argument "-NoProfile -NonInteractive -File `"$(Join-Path $Root 'Invoke-CheckinWorker.ps1')`" -ConfigPath `"$ConfigPath`"" -WorkingDirectory $Root -ErrorAction Stop
$listenerSettings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ErrorAction Stop
$workerSettings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 1) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ErrorAction Stop
$listenerTask=New-ScheduledTask -Action $listenerAction -Trigger (New-ScheduledTaskTrigger -AtStartup -ErrorAction Stop) -Settings $listenerSettings -Description 'Receives SPP check-in events. Stays running; no periodic SPP API polling.' -ErrorAction Stop
$workerTask=New-ScheduledTask -Action $workerAction -Settings $workerSettings -Description 'On-demand worker. Verifies SPP audit events, deduplicates, then runs fixed-password change/check.' -ErrorAction Stop
try {
    $existingTasks=@(Get-ScheduledTask -TaskPath '\' -ErrorAction Stop)
    $definitions=@(
        @{Name=$Config.WorkerTaskName;Task=$workerTask;Action=$workerAction;Listener=$false},
        @{Name=$Config.ListenerTaskName;Task=$listenerTask;Action=$listenerAction;Listener=$true}
    )
    # Validate all existing resources before attempting any registration.
    foreach($definition in $definitions) {
        $matches=@($existingTasks | Where-Object {$_.TaskName -eq $definition.Name})
        if($matches.Count -gt 1){throw 'Ambiguous existing task.'}
        $definition.Existing=$matches.Count -eq 1
        if($definition.Existing){Assert-ExistingTask $matches[0] $definition.Action $definition.Task.Description $definition.Listener}
    }
    $beforeAcl=(Get-Acl -LiteralPath $Root).Sddl
    $snapshot=Join-Path $Runtime 'installation-before.json'
    if(!(Test-Path -LiteralPath $snapshot)){Write-AtomicJson $snapshot @{AclSddl=$beforeAcl;FirewallExisted=[bool]$existingFirewall.Count;Utc=[DateTime]::UtcNow.ToString('o')}}
    Set-Acl -LiteralPath $Root -AclObject $acl -ErrorAction Stop
    Write-Log 'installation' 'Deployment root ACL restricted; before SDDL retained locally.'
    $password=$WindowsCredential.GetNetworkCredential().Password
    foreach($definition in $definitions) {
        if(!$definition.Existing) {
            # Explicit Stop is required even when cmdlets are compatibility proxies.
            $null=Register-ScheduledTask -TaskPath '\' -TaskName $definition.Name -InputObject $definition.Task -User $WindowsCredential.UserName -Password $password -ErrorAction Stop
        }
        $registered=Get-ScheduledTask -TaskPath '\' -TaskName $definition.Name -ErrorAction Stop
        if(!$registered){throw 'Registration did not produce a task.'}
        Assert-ExistingTask $registered $definition.Action $definition.Task.Description $definition.Listener
    }
    $password=$null
    if(!$SkipFirewallConfiguration) {
        if(!$existingFirewall.Count) {
            $null=New-NetFirewallRule -Name $firewallName -DisplayName $firewallName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Config.Port -RemoteAddress $Config.AllowedSources -Program $pwsh -Profile Any -ErrorAction Stop
        }
        $firewall=Get-NetFirewallRule -Name $firewallName -PolicyStore PersistentStore -ErrorAction Stop
        if(!$firewall){throw 'Firewall rule could not be read back.'}
        Assert-ExistingFirewall $firewall
    }
    $listener=Get-ScheduledTask -TaskPath '\' -TaskName $Config.ListenerTaskName -ErrorAction Stop
    if([string]$listener.State -notin @('Running','4','Queued','2')){Start-ScheduledTask -InputObject $listener -ErrorAction Stop}
    $ready=$false
    for($attempt=0;$attempt -lt 15;$attempt++) {
        Start-Sleep -Seconds 1
        $listener=Get-ScheduledTask -TaskPath '\' -TaskName $Config.ListenerTaskName -ErrorAction Stop
        $port=@(Get-NetTCPConnection -State Listen -LocalAddress $Config.ListenAddress -LocalPort $Config.Port -ErrorAction SilentlyContinue)
        if([string]$listener.State -in @('Running','4') -and $port.Count){$ready=$true;break}
    }
    if(!$ready){throw 'Listener did not reach Running with its TCP port open. Check receiver logs and task history.'}
    Write-Log 'installation' 'Both task definitions verified; listener running; firewall verified or externally managed.'
    Write-Host 'Installed and verified: both tasks exist; listener is Running and TCP port is listening.'
    Write-Host 'SPP notification delivery still requires the check-in test.'
} catch {
    Write-Warning 'Installation incomplete. Matching resources are retained for a safe rerun. Do not reinitialize or delete runtime state.'
    throw
} finally {$password=$null;$WindowsCredential=$null}
