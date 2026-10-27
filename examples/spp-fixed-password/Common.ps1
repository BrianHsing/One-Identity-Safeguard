#requires -Version 7.0
Set-StrictMode -Version 3
$ErrorActionPreference='Stop'
function Read-Configuration {
    param([string]$Path)
    $script:Root=Split-Path ([IO.Path]::GetFullPath($Path))
    $script:Config=Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($Config.Appliance -notmatch '\A[A-Za-z0-9.-]+\z') { throw 'Invalid appliance host.' }
    if ($Config.Port -lt 1024 -or $Config.Port -gt 32767) { throw 'Invalid receiver port.' }
    foreach($id in @($Config.AccountId,$Config.AssetId,$Config.SyncGroupId)) {
        if($id -isnot [long] -and $id -isnot [int]){throw 'IDs must be integers.'}
        if($id -lt 1){throw 'Replace sample IDs with actual positive IDs.'}
    }
    if($Config.ExpectedAddress -match '[<>"\r\n]' -or $Config.ExpectedAccountName -match '[<>"\r\n]'){throw 'Replace placeholders; quotes/newlines are unsupported.'}
    if($Config.ListenerTaskName -eq $Config.WorkerTaskName){throw 'Task names must differ.'}
    foreach($name in @($Config.ListenerTaskName,$Config.WorkerTaskName)) {if($name -notmatch '\A[A-Za-z0-9_-]{1,100}\z'){throw 'Invalid task name.'}}
    $ip=$null
    if(![Net.IPAddress]::TryParse($Config.ListenAddress,[ref]$ip) -or $Config.ListenAddress -in @('0.0.0.0','::')){throw 'Use a specific listener IP.'}
    if(!$Config.AllowedSources.Count){throw 'AllowedSources must not be empty.'}
    foreach($source in $Config.AllowedSources){if(![Net.IPAddress]::TryParse($source,[ref]$ip) -or $source -in @('0.0.0.0','::')){throw 'AllowedSources requires exact SPP IPs.'}}
    $script:Runtime=Join-Path $Root 'runtime'
    foreach($folder in @($Runtime,(Join-Path $Runtime 'queue'),(Join-Path $Runtime 'logs'))) {
        $null=New-Item -ItemType Directory -Path $folder -Force
    }
    $script:CredentialPath=if([IO.Path]::IsPathRooted($Config.CredentialFile)){$Config.CredentialFile}else{Join-Path $Root $Config.CredentialFile}
}
function Write-Log {
    param([string]$Component,[string]$Message)
    $record=[ordered]@{Utc=[DateTime]::UtcNow.ToString('o');Component=$Component;Message=$Message}
    $file=Join-Path $Runtime ('logs/'+$Component+'-'+[DateTime]::UtcNow.ToString('yyyyMMdd')+'.jsonl')
    $record | ConvertTo-Json -Compress | Add-Content -LiteralPath $file -Encoding utf8
}
function Write-AtomicJson {
    param([string]$Path,[object]$Value)
    $tmp=$Path+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    try {
        $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $tmp -Encoding utf8
        [IO.File]::Move($tmp,$Path,$true)
    } finally { if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp} }
}
function Get-QueueKey {
    param([string]$Value)
    $sha=[Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Value)))).Replace('-','').ToLowerInvariant() }
    finally {$sha.Dispose()}
}
function Get-SafeFailureDetails {
    param([System.Management.Automation.ErrorRecord]$Record,[string]$Stage)
    # Deliberately exclude exception messages, invocation text, headers and bodies.
    [ordered]@{
        Stage=$Stage
        ErrorType=$Record.Exception.GetType().FullName
        ErrorId=($Record.FullyQualifiedErrorId -split ',')[0]
        Script=[IO.Path]::GetFileName($Record.InvocationInfo.ScriptName)
        Line=$Record.InvocationInfo.ScriptLineNumber
    }
}
function Invoke-SppApi {
    param([string]$Method,[string]$Path,[object]$Body,[switch]$AbsolutePath)
    $uri=if($AbsolutePath){"https://$($Config.Appliance)$Path"}else{"https://$($Config.Appliance)/service/core/v4/$Path"}
    $args=@{Uri=$uri;Method=$Method;Headers=$script:ApiHeaders;ContentType='application/json';TimeoutSec=30;ErrorAction='Stop'}
    if($Config.SkipCertificateCheck){$args.SkipCertificateCheck=$true}
    if($PSBoundParameters.ContainsKey('Body')){$args.Body=[Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $Body -Depth 30 -Compress))}
    try { $response=Invoke-RestMethod @args; return $response }
    catch {
        $responseProperty=$_.Exception.PSObject.Properties['Response']
        $status=if($responseProperty -and $responseProperty.Value){[int]$responseProperty.Value.StatusCode}else{'unavailable'}
        $type=$_.Exception.GetType().Name
        throw "SPP $Method $($Path.Split('?')[0]) failed (HTTP $status; $type). No request body or credential is logged; writes are not automatically retried."
    }
}
function Open-SppSession {
    param([pscredential]$Credential)
    $script:ApiHeaders=@{Accept='application/json'}
    if(!$Credential){$credential=Import-Clixml -LiteralPath $CredentialPath}
    if($credential -isnot [pscredential]){throw 'Credential file is invalid.'}
    $loginBody=@{grant_type='password';username=$credential.UserName;password=$credential.GetNetworkCredential().Password;scope='rsts:sts:primaryproviderid:local'}
    try {
        $sts=Invoke-SppApi POST '/RSTS/oauth2/token' -Body $loginBody -AbsolutePath
        $login=Invoke-SppApi POST 'Token/LoginResponse' -Body @{StsAccessToken=$sts.access_token}
        if($login.Status -ne 'Success'){throw 'SPP authentication failed.'}
        $script:ApiHeaders.Authorization='Bearer '+$login.UserToken
    } finally {$loginBody.Clear();$credential=$null;$sts=$null;$login=$null}
}
function Close-SppSession {
    if($script:ApiHeaders.ContainsKey('Authorization')) {
        try {$null=Invoke-SppApi POST 'Token/Logout'}catch{Write-Log 'worker' 'SPP logout was not confirmed.'}
    }
    $script:ApiHeaders.Clear()
}
