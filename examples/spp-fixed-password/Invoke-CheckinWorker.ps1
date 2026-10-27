#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param([string]$ConfigPath=(Join-Path $PSScriptRoot 'config.json'),[switch]$Initialize,[switch]$InspectOnly)
if (($WhatIfPreference -or !$InspectOnly) -and !$PSCmdlet.ShouldProcess($ConfigPath, 'Initialize or process check-ins and fixed-password operations')) { return }
if (!$IsWindows) { throw 'This deployment requires Windows and DPAPI.' }
. (Join-Path $PSScriptRoot 'Common.ps1')
Read-Configuration $ConfigPath
$workerLock=$null;$connected=$false;$stage='AcquireWorkerLock'
try {
    $workerLock=[IO.File]::Open((Join-Path $Runtime 'worker.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $watcher=Join-Path $Root 'SPP-Windows-TARGET_ACCOUNT-OnCheckin_v1.ps1'
    $arguments=@{Appliance=$Config.Appliance;AccountId=$Config.AccountId;AssetId=$Config.AssetId;SyncGroupId=$Config.SyncGroupId;
        ExpectedAddress=$Config.ExpectedAddress;ExpectedAccountName=$Config.ExpectedAccountName;
        RunnerPath=(Join-Path $Root 'SPP-Windows-TARGET_ACCOUNT-FixedPassword_v1.ps1');StatePath=(Join-Path $Runtime 'checkin-state.json');
        CredentialFile=$CredentialPath;SkipCertificateCheck=[bool]$Config.SkipCertificateCheck;Confirm=$false}
    if($Initialize){& $watcher @arguments -Initialize;Write-Log 'worker' 'Initialized baseline. Historical events skipped.';return}
    if($InspectOnly){& $watcher @arguments -InspectOnly;return}
    if(Test-Path (Join-Path $Runtime 'blocked.json')){throw 'Processing is blocked pending manual review.'}
    $files=@(Get-ChildItem (Join-Path $Runtime 'queue') -Filter '*.json' | Sort-Object LastWriteTimeUtc)
    if(!$files.Count){return}
    $stage='Authenticate'
    Open-SppSession;$connected=$true
    $stage='CheckRunningTasks'
    $running=@(Invoke-SppApi GET 'RunningTasks')
    if(@($running|Where-Object{
        ($_.PSObject.Properties['AccountId'] -and $_.AccountId -eq $Config.AccountId) -or
        ($_.PSObject.Properties['SyncGroupId'] -and $_.SyncGroupId -eq $Config.SyncGroupId)
    }).Count) {
        Write-Log 'worker' 'Account/group is busy; deferred without changing passwords.';return
    }
    $confirmed=[Collections.Generic.List[object]]::new()
    foreach($file in $files) {
        $stage='VerifyNotification'
        $notice=Get-Content $file.FullName -Raw|ConvertFrom-Json
        if($notice.Kind -eq 'Reconcile'){$confirmed.Add($file);continue}
        if($notice.Kind -ne 'Checkin' -or $notice.RequestId -notmatch '\A[A-Za-z0-9-]{1,200}\z'){throw 'Invalid queue item.'}
        $filter="AccountId eq $($Config.AccountId) and AssetId eq $($Config.AssetId) and EventName eq 'AccessRequestCheckedIn' and RequestId eq '$($notice.RequestId)'"
        $verified=$false
        # Only a pushed event causes these bounded reads; no idle API polling.
        for($attempt=0;$attempt -lt 6;$attempt++) {
            $rows=@(Invoke-SppApi GET ('AuditLog/AccessRequests/Activities?filter='+[uri]::EscapeDataString($filter)+'&limit=100'))
            if(@($rows|Where-Object{$_.EventName -ceq 'AccessRequestCheckedIn' -and $_.RequestId -ceq $notice.RequestId -and $_.AccountId -eq $Config.AccountId -and $_.AssetId -eq $Config.AssetId}).Count){$verified=$true;break}
            if($attempt -lt 5){Start-Sleep -Seconds 2}
        }
        if(!$verified) {
            # Keep evidence, but never let an unverified syslog message reset a password.
            $rejected=Join-Path $Runtime 'rejected';$null=New-Item -ItemType Directory $rejected -Force
            Move-Item -LiteralPath $file.FullName -Destination (Join-Path $rejected ($file.BaseName+'-'+[guid]::NewGuid().ToString('N')+'.json'))
            Write-Log 'worker' "Unverified notification retained in rejected: $($notice.RequestId). No change triggered by this notification."
            continue
        }
        $confirmed.Add($file)
    }
    if(!$confirmed.Count){return}
    $arguments.Remove('CredentialFile')
    $arguments.AccessToken=ConvertTo-SecureString ($script:ApiHeaders.Authorization.Substring(7)) -AsPlainText -Force
    $stage='ProcessCheckins'
    $results=& $watcher @arguments
    foreach($result in @($results)) {
        Write-Log 'worker' (ConvertTo-Json -InputObject $result -Depth 5 -Compress)
    }
    # Only remove the exact files captured before the run; later arrivals stay queued.
    $stage='AcknowledgeQueue'
    foreach($file in $confirmed){Remove-Item -LiteralPath $file.FullName}
} catch {
    if($workerLock -and !$Initialize -and !$InspectOnly) {
        $failure=Get-SafeFailureDetails -Record $_ -Stage $stage
        # Preserve the first failure when a blocked worker is invoked again.
        if(!(Test-Path (Join-Path $Runtime 'blocked.json'))) {
            Write-AtomicJson (Join-Path $Runtime 'blocked.json') @{Utc=[DateTime]::UtcNow.ToString('o');Reason='Worker failed. Inspect SPP task results and checkin-state.json before resuming.';Failure=$failure}
            Write-Log 'worker' (ConvertTo-Json -InputObject $failure -Depth 5 -Compress)
        }
        Write-Log 'worker' 'Processing blocked; queue and per-event state retained. Inspect SPP task results before resuming.'
    }
    throw
} finally {
    if($connected){Close-SppSession}
    if($workerLock){$workerLock.Dispose()}
    $arguments=$null
}
