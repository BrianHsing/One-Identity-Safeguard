#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [string]$ConfigPath=(Join-Path $PSScriptRoot 'config.json'),
    [string]$TaskName='SPP-FixedPassword-Daily',
    [ValidatePattern('^([01][0-9]|2[0-3]):[0-5][0-9]$')][string]$Time='03:00'
)
if (!$PSCmdlet.ShouldProcess($ConfigPath, 'Register daily task')) { return }
if (!$IsWindows) { throw 'This deployment requires Windows and DPAPI.' }
. (Join-Path $PSScriptRoot 'Common.ps1')
Read-Configuration $ConfigPath
foreach($path in @($CredentialPath,(Join-Path $Root 'fixed-password.xml'))) {
    if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw 'Create both protected credential XML files under the scheduled Windows user first.'}
    if((Import-Clixml -LiteralPath $path) -isnot [pscredential]){throw 'Credential XML is invalid or cannot be decrypted by this user.'}
}
foreach($value in @($Root,$CredentialPath,$Config.Appliance,$Config.ExpectedAddress,$Config.ExpectedAccountName)) {
    if([string]$value -match '["\r\n]'){throw 'Unsupported quote or line break in task parameter.'}
}
if(@(@($Config.AccountId,$Config.SyncGroupId) | Where-Object {$_ -lt 1}).Count){throw 'AccountId and SyncGroupId must be positive.'}
if(Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue){throw 'A task with this name already exists. Review it rather than replacing it.'}
$pwsh=Join-Path $PSHOME 'pwsh.exe'
$runner=Join-Path $Root 'SPP-Windows-TARGET_ACCOUNT-FixedPassword_v1.ps1'
if(!(Test-Path -LiteralPath $runner -PathType Leaf)){throw 'Password runner is missing.'}
$arguments="-NoProfile -NonInteractive -File `"$runner`" -Appliance `"$($Config.Appliance)`" -AccountId $($Config.AccountId) -SyncGroupId $($Config.SyncGroupId) -ExpectedAddress `"$($Config.ExpectedAddress)`" -ExpectedAccountName `"$($Config.ExpectedAccountName)`" -CredentialFile `"$CredentialPath`""
if($Config.SkipCertificateCheck){$arguments+=' -SkipCertificateCheck'}
$identity=[Security.Principal.WindowsIdentity]::GetCurrent().Name
$action=New-ScheduledTaskAction -Execute $pwsh -Argument $arguments -WorkingDirectory $Root
$trigger=New-ScheduledTaskTrigger -Daily -At ([datetime]::Today.Add([timespan]::Parse($Time)))
$principal=New-ScheduledTaskPrincipal -UserId $identity -LogonType Interactive -RunLevel Limited
$settings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 1)
Write-Log 'installation' 'Daily task before=absent; registration requested.'
$null=Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -ErrorAction Stop
Write-Log 'installation' 'Daily task after=registered; interactive logon required.'
$info=Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction Stop
[pscustomobject]@{Task=$TaskName;WindowsUser=$identity;DailyTime=$Time;NextRun=$info.NextRunTime;LogonMode='Interactive';PasswordChangesSubmitted=0}
