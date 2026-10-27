#requires -Version 7.0
<#
Recover one failed event only after read-only SPP checks find no password tasks
since that check-in. Default is preview. -Apply archives the original evidence
and approves one retry; the running Listener then dispatches the retained queue.
This is NOT a recovery tool for a submitted/failed/uncertain password task.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [string]$ConfigPath=(Join-Path $PSScriptRoot 'config.json'),
    [Parameter(Mandatory)][guid]$EventId,
    [switch]$Apply
)
if (($WhatIfPreference -or $Apply) -and !$PSCmdlet.ShouldProcess($ConfigPath, 'Approve one retry and release blocked worker')) { return }
if (!$IsWindows) { throw 'This deployment requires Windows and DPAPI.' }
. (Join-Path $PSScriptRoot 'Common.ps1')
Read-Configuration $ConfigPath
$workerLock=$null;$runnerLock=$null;$connected=$false;$token=$null
try {
    $workerLock=[IO.File]::Open((Join-Path $Runtime 'worker.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $operationPath=Join-Path $Runtime 'password-operation.json'
    if(Test-Path -LiteralPath $operationPath) {
        $operation=Get-Content -LiteralPath $operationPath -Raw | ConvertFrom-Json
        if($operation.Stage -ne 'Completed'){throw 'Unresolved group-password write or task submission. Automatic recovery prohibited.'}
    }
    $statePath=Join-Path $Runtime 'checkin-state.json'
    $blockedPath=Join-Path $Runtime 'blocked.json'
    if(!(Test-Path -LiteralPath $blockedPath)){throw 'Worker is not blocked. This recovery does not apply.'}
    $state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable
    if($state.Version -ne 1 -or $state.Appliance -ne $Config.Appliance -or $state.AccountId -ne $Config.AccountId -or
       $state.AssetId -ne $Config.AssetId -or $state.SyncGroupId -ne $Config.SyncGroupId){throw 'State/config identity mismatch.'}
    $key=$EventId.ToString()
    if(!$state.Events.ContainsKey($key)){throw 'The specified event is not in local state.'}
    $entry=$state.Events[$key]
    if($entry.Status -ne 'NeedsReview'){throw 'Only a NeedsReview event can use this recovery.'}
    if($entry.ContainsKey('ChangeTaskId') -or $entry.ContainsKey('CheckTaskId')){throw 'A task identity is already recorded. Inspect that task; do not retry.'}
    $otherUnresolved=@($state.Events.Keys | Where-Object{$_ -ne $key -and $state.Events[$_].Status -in @('NeedsReview','InProgress','RetryApproved')})
    if($otherUnresolved.Count){throw 'Other events need review. Resolve them before resuming.'}
    if(!$entry.StartedUtc -or !$entry.FailureUtc -or $entry.RequestId -notmatch '\A[A-Za-z0-9-]{1,200}\z'){throw 'Incomplete or invalid failed-event state.'}
    $checkinTime=([DateTimeOffset]$entry.LogTime).ToUniversalTime()
    $started=([DateTimeOffset]$entry.StartedUtc).ToUniversalTime()
    $failed=([DateTimeOffset]$entry.FailureUtc).ToUniversalTime()
    if($failed -lt $started -or $checkinTime -gt $failed){throw 'Failed-event timestamps are inconsistent.'}
    if($state.Cursor -and $checkinTime -lt ([DateTimeOffset]$state.Cursor).ToUniversalTime().AddMinutes(-10)){throw 'Event is outside the watcher replay window. Manual review required.'}
    $queue=@(Get-ChildItem (Join-Path $Runtime 'queue') -Filter '*.json' | Where-Object {
        $item=Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
        $item.Kind -eq 'Checkin' -and $item.RequestId -ceq $entry.RequestId
    })
    if(!$queue.Count){throw 'The original check-in notification is not queued. No state was changed.'}

    Open-SppSession;$connected=$true
    $token=ConvertTo-SecureString ($script:ApiHeaders.Authorization.Substring(7)) -AsPlainText -Force
    $inspect=@{Appliance=$Config.Appliance;AccountId=$Config.AccountId;SyncGroupId=$Config.SyncGroupId;
        ExpectedAddress=$Config.ExpectedAddress;ExpectedAccountName=$Config.ExpectedAccountName;
        AccessToken=$token;SkipCertificateCheck=[bool]$Config.SkipCertificateCheck;InspectOnly=$true}
    $preflight=& (Join-Path $Root 'SPP-Windows-TARGET_ACCOUNT-FixedPassword_v1.ps1') @inspect
    if($preflight.Mode -ne 'InspectOnly'){throw 'Runner read-only preflight was not confirmed.'}
    $runnerLock=[IO.File]::Open((Join-Path $Runtime 'password-runner.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $running=@(Invoke-SppApi GET 'RunningTasks')
    if(@($running | Where-Object {
        ($_.PSObject.Properties['AccountId'] -and $_.AccountId -eq $Config.AccountId) -or
        ($_.PSObject.Properties['SyncGroupId'] -and $_.SyncGroupId -eq $Config.SyncGroupId)
    }).Count){throw 'The account/group has running work. No state was changed.'}
    $filter="AccountId eq $($Config.AccountId) and AssetId eq $($Config.AssetId) and EventName eq 'AccessRequestCheckedIn' and RequestId eq '$($entry.RequestId)'"
    $events=@(Invoke-SppApi GET ('AuditLog/AccessRequests/Activities?filter='+[uri]::EscapeDataString($filter)+'&limit=100'))
    $match=@($events | Where-Object {$_.Id -eq $key -and $_.EventName -ceq 'AccessRequestCheckedIn' -and
        $_.AccountId -eq $Config.AccountId -and $_.AssetId -eq $Config.AssetId -and $_.RequestId -ceq $entry.RequestId})
    if($match.Count -ne 1 -or [Math]::Abs((([DateTimeOffset]$match[0].LogTime).ToUniversalTime()-$checkinTime).TotalSeconds) -gt 1){throw 'SPP did not confirm the exact original check-in event.'}
    $since=if($checkinTime -lt $started){$checkinTime}else{$started}
    $since=$since.AddSeconds(-5).ToString('o')
    $tasks=@(Invoke-SppApi GET ('AuditLog/Passwords?accountId='+$Config.AccountId+'&startDate='+[uri]::EscapeDataString($since)+'&orderby=-LogTime&limit=2'))
    if($tasks.Count){throw 'SPP has password-task records after this check-in. Do not use this recovery; inspect those tasks first.'}
    if(!$Apply){
        [pscustomobject]@{Mode='Preview';CanResume=$true;EventId=$key;RequestId=$entry.RequestId;PasswordTasksSince=$since;PasswordTaskCount=0;QueueItems=$queue.Count;PasswordChangesSubmitted=0}
        return
    }
    $archive=Join-Path $Runtime ('recovery/'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')+'-'+[guid]::NewGuid().ToString('N'))
    $null=New-Item -ItemType Directory -Path $archive -Force
    Copy-Item -LiteralPath $statePath -Destination (Join-Path $archive 'checkin-state.json')
    Copy-Item -LiteralPath $blockedPath -Destination (Join-Path $archive 'blocked.json')
    $oldState=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable
    $entry.Status='RetryApproved'
    $entry.RetryApprovedUtc=[DateTime]::UtcNow.ToString('o')
    $entry.RecoveryEvidence=@{Archive=$archive;PasswordTaskCount=0;TasksCheckedSince=$since}
    Write-AtomicJson $statePath $state
    try {
        # Keep blocked until the updated state is durable. Never erase the queue.
        Move-Item -LiteralPath $blockedPath -Destination (Join-Path $archive 'blocked-original.json') -ErrorAction Stop
    } catch {
        if(Test-Path -LiteralPath $blockedPath){Write-AtomicJson $statePath $oldState}
        throw
    }
    Write-Log 'worker' "Retry approved after read-only SPP review for event $key; original evidence archived."
    [pscustomobject]@{Mode='RetryApproved';EventId=$key;Archive=$archive;QueueItems=$queue.Count;PasswordChangesSubmitted=0;Next='Listener will request the Worker for the retained queue.'}
} finally {
    if($connected){Close-SppSession}
    if($runnerLock){$runnerLock.Dispose()}
    if($workerLock){$workerLock.Dispose()}
    $token=$null
}
