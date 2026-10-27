#requires -Version 7.0
# Runs once when invoked by the event worker. No periodic trigger is needed.
# Initialize on that host once before enabling the schedule. Historical check-ins
# are acknowledged without changing passwords. No administrator password is stored.
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [string]$Appliance = '<CUSTOMER_SPP_HOST>',
    [int]$AccountId = 1,
    [int]$AssetId = 1,
    [int]$SyncGroupId = 1,
    [string]$ExpectedAddress = '<CUSTOMER_TARGET_HOST>',
    [string]$ExpectedAccountName = '<CUSTOMER_TARGET_ACCOUNT>',
    [string]$RunnerPath = (Join-Path $PSScriptRoot 'SPP-Windows-TARGET_ACCOUNT-FixedPassword_v1.ps1'),
    [string]$StatePath = (Join-Path $PSScriptRoot 'checkin-state.json'),
    [pscredential]$Credential,
    [string]$CredentialFile,
    [Security.SecureString]$AccessToken,
    [switch]$Initialize,
    [switch]$InspectOnly,
    [switch]$SkipCertificateCheck
)
if (($WhatIfPreference -or !$InspectOnly) -and !$PSCmdlet.ShouldProcess("$Appliance / account $AccountId", 'Initialize baseline or process check-ins')) { return }
if (!$IsWindows) { throw 'This deployment requires Windows and DPAPI.' }
$ErrorActionPreference = 'Stop'
if ($Initialize -and $InspectOnly) { throw 'Choose Initialize or InspectOnly.' }
if ($Appliance -notmatch '\A[A-Za-z0-9.-]+(?::[0-9]+)?\z') { throw 'Invalid appliance host.' }
if (($Credential -and $CredentialFile) -or ($AccessToken -and ($Credential -or $CredentialFile))) {
    throw 'Choose one authentication method.'
}
$StatePath = [IO.Path]::GetFullPath($StatePath)
$base = "https://$Appliance"
$headers = @{ Accept='application/json' }
$ownsLogin = $false
$hasLock = $false
$mutex = $null
function Save-WatcherState {
    $temporary = $StatePath + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    try {
        $state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $temporary -Encoding utf8
        [IO.File]::Move($temporary, $StatePath, $true)
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
    }
}
function Get-CheckinEvents {
    param([string]$Cursor)
    $filter = "AccountId eq $AccountId and EventName eq 'AccessRequestCheckedIn'"
    if ($Cursor) { $filter += " and LogTime ge '$Cursor'" }
    $escaped = [uri]::EscapeDataString($filter)
    for ($page=0; $page -lt 1000; $page++) {
        $rows = @(Invoke-LabRequest GET "AuditLog/AccessRequests/Activities?filter=$escaped&orderby=LogTime&limit=100&page=$page")
        foreach ($row in $rows) {
            if ($row.EventName -ne 'AccessRequestCheckedIn' -or [int]$row.AccountId -ne $AccountId -or [int]$row.AssetId -ne $AssetId) {
                throw 'Unexpected audit event identity. No password change submitted.'
            }
            if (!$row.Id -or !$row.RequestId -or !$row.LogTime) { throw 'Incomplete audit event.' }
            $row
        }
        if ($rows.Count -lt 100) { return }
    }
    throw 'Audit pagination limit reached; inspect before continuing.'
}
function Invoke-LabRequest {
    param([string]$Method, [string]$Path, [object]$Body, [switch]$AbsolutePath)
    $uri = if ($AbsolutePath) { "$base$Path" } else { "$base/service/core/v4/$Path" }
    $invokeArgs = @{ Method=$Method; Uri=$uri; Headers=$headers; ContentType='application/json'; TimeoutSec=45; ErrorAction='Stop' }
    if ($SkipCertificateCheck) { $invokeArgs.SkipCertificateCheck = $true }
    if ($PSBoundParameters.ContainsKey('Body')) {
        $invokeArgs.ContentType = 'application/json'
        $invokeArgs.Body = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $Body -Depth 40 -Compress))
    }
    try { $response = Invoke-RestMethod @invokeArgs; return $response }
    catch {
        $responseProperty = $_.Exception.PSObject.Properties['Response']
        $status = if ($responseProperty -and $responseProperty.Value) { [int]$responseProperty.Value.StatusCode } else { 'unavailable' }
        # Never echo credentials, request bodies, headers, or response bodies.
        throw "SPP $Method $Path failed (HTTP $status). Writes are not retried; inspect SPP before rerunning."
    }
}

try {
    $mutex = [Threading.Mutex]::new($false, "Local\SPPCheckin-$Appliance-$AccountId")
    try { $hasLock = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $hasLock = $true }
    if (!$hasLock) { throw 'Another check-in watcher is running.' }
    if (!$InspectOnly -and !(Test-Path -LiteralPath $RunnerPath -PathType Leaf)) { throw 'Password runner not found.' }
    if (!$InspectOnly -and !$Initialize -and !(Test-Path -LiteralPath $StatePath)) {
        throw 'Initialize this watcher on the deployment host before scheduling it.'
    }
    if ($Initialize -and (Test-Path -LiteralPath $StatePath)) {
        throw 'State already exists. Do not reinitialize or erase pending/failed events.'
    }
    if ($AccessToken) {
        $headers.Authorization = 'Bearer ' + [Net.NetworkCredential]::new('', $AccessToken).Password
    } else {
        if ($CredentialFile) {
            $Credential = Import-Clixml -LiteralPath $CredentialFile
            if ($Credential -isnot [pscredential]) { throw 'CredentialFile must contain a PSCredential.' }
        }
        if (!$Credential) { $Credential = Get-Credential -Message 'SPP API login' }
        if (!$Credential) { throw 'No credential supplied.' }
        $loginBody = @{ grant_type='password'; username=$Credential.UserName;
            password=$Credential.GetNetworkCredential().Password; scope='rsts:sts:primaryproviderid:local' }
        $sts = Invoke-LabRequest POST '/RSTS/oauth2/token' -Body $loginBody -AbsolutePath
        $loginBody.Clear()
        $login = Invoke-LabRequest POST 'Token/LoginResponse' -Body @{StsAccessToken=$sts.access_token}
        $sts = $null
        if ($login.Status -ne 'Success' -or !$login.UserToken) { throw 'SPP login did not complete successfully.' }
        $headers.Authorization = 'Bearer ' + $login.UserToken
        $ownsLogin = $true
        $login = $null
    }

    $account = Invoke-LabRequest GET "AssetAccounts/$AccountId"
    if ($account.Name -cne $ExpectedAccountName -or $account.Asset.NetworkAddress -cne $ExpectedAddress -or [int]$account.Asset.Id -ne $AssetId) {
        throw 'Target account identity mismatch.'
    }
    if ([int]$account.SyncGroup.Id -ne $SyncGroupId) { throw 'Sync group mismatch.' }
    if ($InspectOnly) {
        $events = @(Get-CheckinEvents)
        [pscustomobject]@{Mode='InspectOnly'; Account=$account.Name; ExistingCheckins=$events.Count; PasswordChangesSubmitted=0}
        $events | Select-Object Id, LogTime, RequestId, EventName
        return
    }
    if ($Initialize) {
        $events = @(Get-CheckinEvents)
        $state = @{Version=1; Appliance=$Appliance; AccountId=$AccountId; AssetId=$AssetId; SyncGroupId=$SyncGroupId; Cursor=$null; Events=@{}}
        foreach ($event in $events) {
            $state.Events[$event.Id] = @{Status='Baseline'; RequestId=$event.RequestId; LogTime=([DateTimeOffset]$event.LogTime).ToUniversalTime().ToString('o')}
        }
        if ($events.Count) { $state.Cursor = ([DateTimeOffset]$events[-1].LogTime).ToUniversalTime().ToString('o') }
        Save-WatcherState
        [pscustomobject]@{Mode='Initialized'; HistoricalEventsSkipped=$events.Count; StatePath=$StatePath; PasswordChangesSubmitted=0}
        return
    }
    $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json -AsHashtable
    if ($state.Version -ne 1 -or $state.Appliance -ne $Appliance -or $state.AccountId -ne $AccountId -or $state.AssetId -ne $AssetId -or $state.SyncGroupId -ne $SyncGroupId) {
        throw 'State file identity mismatch.'
    }
    $unresolved = @($state.Events.Values | Where-Object {$_.Status -in @('InProgress','NeedsReview')})
    if ($unresolved.Count) { throw 'An earlier event failed or was interrupted. Inspect SPP and the state file before resuming. No automatic retry.' }
    $cursor = if ($state.Cursor) { ([DateTimeOffset]$state.Cursor).ToUniversalTime().AddMinutes(-10).ToString('o') } else { $null }
    $events = @(Get-CheckinEvents -Cursor $cursor)
    $processed = 0
    foreach ($event in $events) {
        if ($state.Events.ContainsKey($event.Id) -and $state.Events[$event.Id].Status -ne 'RetryApproved') { continue }
        # A durable claim is written BEFORE invoking any password operation.
        $entry = @{Status='InProgress'; RequestId=$event.RequestId; LogTime=([DateTimeOffset]$event.LogTime).ToUniversalTime().ToString('o'); StartedUtc=[DateTime]::UtcNow.ToString('o')}
        if ($state.Events.ContainsKey($event.Id)) { $entry.PreviousAttempt = $state.Events[$event.Id] }
        $state.Events[$event.Id] = $entry
        Save-WatcherState
        try {
            $secureToken = ConvertTo-SecureString ($headers.Authorization.Substring(7)) -AsPlainText -Force
            $arguments = @{Appliance=$Appliance; AccountId=$AccountId; SyncGroupId=$SyncGroupId;
                ExpectedAddress=$ExpectedAddress; ExpectedAccountName=$ExpectedAccountName;
                AccessToken=$secureToken; SkipCertificateCheck=[bool]$SkipCertificateCheck;Confirm=$false}
            $result = & $RunnerPath @arguments
            if ($result.ChangeState -ne 'Success' -or $result.CheckState -ne 'Success' -or !$result.ChangeTaskId -or !$result.CheckTaskId) {
                throw 'Runner did not return confirmed ChangePassword and CheckPassword success.'
            }
            $entry.Status = 'Success'
            $entry.ChangeTaskId = $result.ChangeTaskId
            $entry.CheckTaskId = $result.CheckTaskId
            $entry.CompletedUtc = $result.CompletedUtc
            Save-WatcherState
            $processed++
            [pscustomobject]@{RequestId=$event.RequestId; EventId=$event.Id; ChangeTaskId=$result.ChangeTaskId; CheckTaskId=$result.CheckTaskId; State='Success'}
        } catch {
            $entry.Status = 'NeedsReview'
            $entry.FailureUtc = [DateTime]::UtcNow.ToString('o')
            Save-WatcherState
            throw
        } finally {
            $secureToken = $null
            $arguments = $null
        }
    }
    if ($events.Count) {
        $state.Cursor = ([DateTimeOffset]$events[-1].LogTime).ToUniversalTime().ToString('o')
        Save-WatcherState
    }
    [pscustomobject]@{Mode='Completed'; NewCheckinsProcessed=$processed}
} finally {
    if ($ownsLogin) { try { $null=Invoke-LabRequest POST 'Token/Logout' } catch { Write-Warning 'SPP logout was not confirmed.' } }
    $headers.Clear()
    if ($hasLock) { $mutex.ReleaseMutex() }
    if ($mutex) { $mutex.Dispose() }
    $Credential=$null
    $AccessToken=$null
    $loginBody=$null
    $login=$null
    $sts=$null
}
