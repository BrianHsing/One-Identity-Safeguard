#requires -Version 7.0
# Synthetic data only. No credentials, sockets, scheduled tasks or SPP requests.
$ErrorActionPreference='Stop'
Set-StrictMode -Version 3
. (Join-Path (Split-Path $PSScriptRoot) 'Receiver.Core.ps1')
$passed=0
function Assert-True([bool]$Condition,[string]$Name) {
    if(!$Condition){throw "FAIL: $Name"}
    $script:passed++
}
function Assert-Throws([scriptblock]$Action,[string]$Name) {
    $caught=$false
    try { & $Action | Out-Null } catch { $caught=$true }
    Assert-True $caught $Name
}
function New-Buffer([byte[]]$Bytes) {
    $buffer=[Collections.Generic.List[byte]]::new()
    $buffer.AddRange($Bytes)
    return ,$buffer
}
$msg='{"EventName":"AccessRequestCheckedIn","AccountId":7,"AssetId":9,"RequestId":"synthetic-1","Note":"測試"}'
$body=[Text.Encoding]::UTF8.GetBytes($msg)
$frame=[Text.Encoding]::ASCII.GetBytes(($body.Length.ToString()+' '))+$body
$buffer=New-Buffer $frame[0..5]
Assert-True (@(Read-SyslogFrames $buffer).Count -eq 0) 'partial frame retained'
$buffer.AddRange([byte[]]$frame[6..($frame.Length-1)])
$decoded=@(Read-SyslogFrames $buffer)
Assert-True ($decoded.Count -eq 1 -and $decoded[0] -ceq $msg -and $buffer.Count -eq 0) 'UTF8 octet counting'
$buffer=New-Buffer ([byte[]]($frame+$frame))
Assert-True (@(Read-SyslogFrames $buffer).Count -eq 2) 'multiple frames in one read'
$buffer=New-Buffer ([Text.Encoding]::UTF8.GetBytes($msg+"`r`n"))
Assert-True (@(Read-SyslogFrames $buffer)[0] -ceq $msg) 'CRLF framing'
$event=Convert-CheckinMessage ('<134>syslog '+$msg) 7 9
Assert-True ($event.RequestId -ceq 'synthetic-1') 'matching flat JSON accepted'
Assert-True ($null -eq (Convert-CheckinMessage $msg 8 9)) 'wrong account rejected'
Assert-True ($null -eq (Convert-CheckinMessage $msg 7 10)) 'wrong asset rejected'
Assert-True ($null -eq (Convert-CheckinMessage ($msg.Replace('AccessRequestCheckedIn','OtherEvent')) 7 9)) 'wrong event rejected'
Assert-True ($null -eq (Convert-CheckinMessage ($msg.Replace('synthetic-1',"unsafe';")) 7 9)) 'unsafe request id rejected'
Assert-True ($null -eq (Convert-CheckinMessage '{bad json' 7 9)) 'malformed JSON rejected'
Assert-True ($null -eq (Convert-CheckinMessage '{"EventName":"AccessRequestCheckedIn"}' 7 9)) 'missing identity rejected'
Assert-Throws { $buf=New-Buffer ([Text.Encoding]::ASCII.GetBytes('131073 ')); Read-SyslogFrames $buf } 'oversize octet frame rejected'
Assert-Throws { $buf=New-Buffer ([Text.Encoding]::ASCII.GetBytes('000000001 ')); Read-SyslogFrames $buf } 'long length header rejected'
Assert-Throws { $buf=New-Buffer ([byte[]]@(49,32,255)); Read-SyslogFrames $buf } 'invalid UTF8 rejected'
Assert-Throws { $buf=New-Buffer ([Text.Encoding]::ASCII.GetBytes(('x'*131073)+"`n")); Read-SyslogFrames $buf } 'oversize LF frame rejected'
Write-Output "PASS: $passed synthetic receiver checks; no external operations."
# Test only the parsed task-wait function with in-memory API responses.
$runnerPath=Join-Path (Split-Path $PSScriptRoot) 'SPP-Windows-TARGET_ACCOUNT-FixedPassword_v1.ps1'
$tokens=$null;$parseErrors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile($runnerPath,[ref]$tokens,[ref]$parseErrors)
if($parseErrors.Count){throw 'Runner parse failed'}
$wait=$ast.FindAll({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Wait-LabTask'},$true)
if($wait.Count -ne 1){throw 'Wait function not found'}
. ([scriptblock]::Create($wait[0].Extent.Text))
function Invoke-LabRequest {
    param($Method,$Path)
    if($Method -ne 'GET' -or $Path -ne 'AuditLog/Passwords/ChangePassword/synthetic-task'){throw 'Unexpected synthetic API request'}
    $script:readCount++
    $state=$script:states.Dequeue()
    return [pscustomobject]@{RequestStatus=[pscustomobject]@{State=$state}}
}
function Start-Sleep { param($Seconds) }
$TimeoutSeconds=15
$script:states=[Collections.Generic.Queue[string]]::new()
foreach($s in @('Accepted','Queued','Running','Success')){$script:states.Enqueue($s)}
$script:readCount=0
$result=Wait-LabTask ([pscustomobject]@{Id='synthetic-task';Name='ChangePassword'})
Assert-True ($result.RequestStatus.State -eq 'Success' -and $script:readCount -eq 4) 'wait for final Success rather than Accepted'
$script:states.Enqueue('Failed')
Assert-Throws {Wait-LabTask ([pscustomobject]@{Id='synthetic-task';Name='ChangePassword'})} 'failed task rejected'
Assert-Throws {Wait-LabTask ([pscustomobject]@{Id='';Name='ChangePassword'})} 'missing task ID rejected'
$script:states.Enqueue('Unexpected')
Assert-Throws {Wait-LabTask ([pscustomobject]@{Id='synthetic-task';Name='ChangePassword'})} 'unknown task state rejected'
Write-Output "PASS: $passed total synthetic checks; only pure receiver and mocked wait functions executed."
