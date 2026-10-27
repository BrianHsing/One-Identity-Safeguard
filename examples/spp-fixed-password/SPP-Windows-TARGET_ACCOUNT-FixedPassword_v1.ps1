#requires -Version 7.0
<#
Set a single-account sync group's password, then run the ACCOUNT ChangePassword.
Do not replace the account call with the group's /Sync call: the latter generated
a different password in the SPP 9.0 lab. See the accompanying measured results.
No administrator credential is embedded. CredentialFile must be a PSCredential
exported with Export-Clixml under the Windows account running this script.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [string]$Appliance = '<CUSTOMER_SPP_HOST>',
    [ValidateRange(1,2147483647)][int]$SyncGroupId = 1,
    [ValidateRange(1,2147483647)][int]$AccountId = 1,
    [string]$ExpectedAddress = '<CUSTOMER_TARGET_HOST>',
    [string]$ExpectedAccountName = '<CUSTOMER_TARGET_ACCOUNT>',
    [pscredential]$Credential,
    [string]$CredentialFile,
    [System.Security.SecureString]$AccessToken,
    [ValidateRange(15,900)][int]$TimeoutSeconds = 180,
    [switch]$InspectOnly,
    [switch]$SkipCertificateCheck
)
if (($WhatIfPreference -or !$InspectOnly) -and !$PSCmdlet.ShouldProcess("$Appliance / account $AccountId / group $SyncGroupId", 'Set fixed group password, ChangePassword and CheckPassword')) { return }
if (!$IsWindows) { throw 'This deployment requires Windows and DPAPI.' }
$ErrorActionPreference = 'Stop'
$fixedPassword = $null
if ($Appliance -notmatch '\A[A-Za-z0-9.-]+(?::[0-9]+)?\z') { throw 'Appliance must be a host name/IP, optionally with port.' }
if (($Credential -and $CredentialFile) -or ($AccessToken -and ($Credential -or $CredentialFile))) {
    throw 'Choose one authentication method: Credential, CredentialFile, or AccessToken.'
}
$base = "https://$Appliance"
$headers = @{ Accept = 'application/json' }
$ownsLogin = $false
$mutex = $null
$hasLock = $false
$taskSubmitted = $false
$processLock = $null
$journal = $null
$journalPath = Join-Path $PSScriptRoot 'runtime/password-operation.json'
function Save-OperationJournal {
    $journal.UpdatedUtc=[DateTime]::UtcNow.ToString('o')
    $tmp=$journalPath+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    try {
        $journal | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $tmp -Encoding utf8
        [IO.File]::Move($tmp,$journalPath,$true)
    } finally {if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp}}
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
    # Materialize first: Invoke-RestMethod otherwise writes a JSON array as one
    # pipeline object, including an empty array. Callers can then use @(...).
    try { $response = Invoke-RestMethod @invokeArgs; return $response }
    catch {
        $responseProperty = $_.Exception.PSObject.Properties['Response']
        $status = if ($responseProperty -and $responseProperty.Value) { [int]$responseProperty.Value.StatusCode } else { 'unavailable' }
        # Never echo credentials, request bodies, headers, or response bodies.
        throw "SPP $Method $Path failed (HTTP $status). Writes are not retried; inspect SPP before rerunning."
    }
}
function Wait-LabTask {
    param([object]$Task)
    if (!$Task.Id -or !$Task.Name) { throw 'SPP returned no task identity.' }
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ($true) {
        $record = Invoke-LabRequest GET "AuditLog/Passwords/$($Task.Name)/$($Task.Id)"
        $state = [string]$record.RequestStatus.State
        if ($state -eq 'Success') { return $record }
        if ($state -notin @('Accepted','Queued','Running')) {
            throw "Task $($Task.Id) ($($Task.Name)) ended with state $state. Read its Log through AuditLog/Passwords; do not retry blindly."
        }
        if ([DateTime]::UtcNow -ge $deadline) {
            throw "Timed out waiting for task $($Task.Id). The task may still be running; inspect SPP before rerunning."
        }
        Start-Sleep -Seconds 2
    }
}
try {
    $lockKey = ($Appliance -replace '[^A-Za-z0-9.-]','_') + "-$SyncGroupId-$AccountId"
    $mutex = [Threading.Mutex]::new($false, "Local\SPPFixedPassword-$lockKey")
    try { $hasLock = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $hasLock = $true }
    if (!$hasLock) { throw 'Another instance is already operating on this target.' }
    $lockDirectory = Join-Path $PSScriptRoot 'runtime'
    $null = New-Item -ItemType Directory -Path $lockDirectory -Force
    $processLock = [IO.File]::Open((Join-Path $lockDirectory 'password-runner.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
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
    $group = Invoke-LabRequest GET "AssetPartitions/SyncGroups/$SyncGroupId"
    if ([int]$group.Id -ne $SyncGroupId -or $null -eq $group.AssetPartitionId -or $null -eq $group.ProfileId) {
        throw 'Unexpected sync group identity.'
    }
    $groupPath = "AssetPartitions/$($group.AssetPartitionId)/Profiles/$($group.ProfileId)/SyncGroups/$SyncGroupId"
    $memberResponse = Invoke-LabRequest GET "$groupPath/Accounts?limit=2"
    $members = @($memberResponse)
    if ($members.Count -ne 1 -or [int]$members[0].Id -ne $AccountId) { throw 'The sync group must contain only the specified account.' }
    $account = Invoke-LabRequest GET "AssetAccounts/$AccountId"
    if ($account.Name -cne $ExpectedAccountName -or $account.Asset.NetworkAddress -cne $ExpectedAddress) {
        throw 'Expected account name/address did not match. No password operation submitted.'
    }
    if ($account.IsServiceAccount -or $account.Disabled -or $group.Disabled) { throw 'Service accounts and disabled targets are not allowed by this runner.' }
    if ([int]$account.SyncGroup.Id -ne $SyncGroupId) { throw 'Account is not assigned to the specified group.' }
    $profile = Invoke-LabRequest GET "AssetPartitions/$($group.AssetPartitionId)/Profiles/$($group.ProfileId)"
    if ($profile.ChangeSchedule.ScheduleType -ne 'Never' -or $profile.CheckSchedule.ResetPasswordOnMismatch) {
        throw 'Use a dedicated profile with ChangeSchedule.ScheduleType Never; automatic group rotation can generate other passwords.'
    }
    $running = @(Invoke-LabRequest GET 'RunningTasks')
    if (@($running | Where-Object {
        ($_.PSObject.Properties['AccountId'] -and $_.AccountId -eq $AccountId) -or
        ($_.PSObject.Properties['SyncGroupId'] -and $_.SyncGroupId -eq $SyncGroupId)
    }).Count) {
        throw 'The account/group already has running work. Wait for completion before starting another run.'
    }
    if ($InspectOnly) {
        [pscustomobject]@{ Mode='InspectOnly'; Appliance=$Appliance; AccountId=$AccountId;
            Account=$account.Name; Address=$account.Asset.NetworkAddress; Group=$group.Name; GroupId=$SyncGroupId }
        return
    }
    if(Test-Path -LiteralPath $journalPath) {
        $previous=Get-Content -LiteralPath $journalPath -Raw | ConvertFrom-Json
        if($previous.Stage -ne 'Completed'){throw 'Previous password operation unresolved. Inspect SPP and journal; do not retry or delete state.'}
        Copy-Item -LiteralPath $journalPath -Destination (Join-Path $lockDirectory ('password-operation-'+[guid]::NewGuid().ToString('N')+'.json'))
    }
    $fixedSecretFile = Join-Path $PSScriptRoot 'fixed-password.xml'
    if (!(Test-Path -LiteralPath $fixedSecretFile)) { throw 'Create fixed-password.xml under the Windows task account first.' }
    $fixedCredential = Import-Clixml -LiteralPath $fixedSecretFile
    if ($fixedCredential -isnot [pscredential]) { throw 'fixed-password.xml must contain a PSCredential.' }
    $fixedPassword = $fixedCredential.GetNetworkCredential().Password
    if ([string]::IsNullOrEmpty($fixedPassword)) { throw 'The fixed password must not be empty.' }
    $fixedCredential = $null
    $journal=[ordered]@{AccountId=$AccountId;GroupId=$SyncGroupId;Stage='GroupPasswordWritePending';PreviousPassword='NotRead';RequestedPassword='ProtectedFile';ChangeTaskId=$null;CheckTaskId=$null;UpdatedUtc=$null}
    Save-OperationJournal
    # Setting the group password marks its members unsynchronized, even when
    # reusing the same value. CheckPassword must run AFTER ChangePassword.
    $null = Invoke-LabRequest PUT "$groupPath/Password" -Body $fixedPassword
    # Critical: call the account endpoint, not the sync-group /Sync endpoint.
    $journal.Stage='ChangeSubmissionPending';Save-OperationJournal
    $task = Invoke-LabRequest POST "AssetAccounts/$AccountId/ChangePassword?extendedLogging=false"
    $taskSubmitted = $true
    $journal.Stage='ChangeSubmitted';$journal.ChangeTaskId=$task.Id;Save-OperationJournal
    Write-Host "ChangePassword task: $($task.Id)"
    $changeResult = Wait-LabTask $task
    $journal.Stage='CheckSubmissionPending';Save-OperationJournal
    $checkTask = Invoke-LabRequest POST "AssetAccounts/$AccountId/CheckPassword?extendedLogging=false"
    $journal.Stage='CheckSubmitted';$journal.CheckTaskId=$checkTask.Id;Save-OperationJournal
    Write-Host "CheckPassword task: $($checkTask.Id)"
    $checkResult = Wait-LabTask $checkTask
    $journal.Stage='Completed';Save-OperationJournal
    [pscustomobject]@{ Appliance=$Appliance; Address=$ExpectedAddress; Account=$ExpectedAccountName;
        GroupId=$SyncGroupId; AccountId=$AccountId; ChangeTaskId=$changeResult.Id;
        ChangeState=$changeResult.RequestStatus.State; CheckTaskId=$checkResult.Id;
        CheckState=$checkResult.RequestStatus.State; CompletedUtc=$checkResult.RequestStatus.EndTime }
} catch {
    if ($taskSubmitted) { Write-Warning 'A password task was submitted. Review its actual status before retrying.' }
    throw
} finally {
    if ($ownsLogin) { try { $null = Invoke-LabRequest POST 'Token/Logout' } catch { Write-Warning "SPP logout was not confirmed: $($_.Exception.Message)" } }
    $headers.Clear()
    if ($hasLock) { $mutex.ReleaseMutex() }
    if ($mutex) { $mutex.Dispose() }
    if ($processLock) { $processLock.Dispose() }
    $Credential = $null
    $AccessToken = $null
    $loginBody = $null
    $sts = $null
    $login = $null
    $fixedPassword = $null
}
