#requires -Version 7.0
[CmdletBinding()]
param([string]$ConfigPath=(Join-Path $PSScriptRoot 'config.json'))
. (Join-Path $PSScriptRoot 'Common.ps1')
Read-Configuration $ConfigPath
$stateNames=@{'0'='Unknown';'1'='Disabled';'2'='Queued';'3'='Ready';'4'='Running'}
foreach($name in @($Config.ListenerTaskName,$Config.WorkerTaskName)) {
    $task=Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
    if($task) {
        $info=Get-ScheduledTaskInfo -InputObject $task
        $state=[string]$task.State
        if($stateNames.ContainsKey($state)){$state=$stateNames[$state]}
        [pscustomobject]@{Task=$name;State=$state;LastRun=$info.LastRunTime;LastResult=$info.LastTaskResult} | Format-List
    } else {Write-Host "Task not installed: $name"}
}
[pscustomobject]@{Initialized=(Test-Path (Join-Path $Runtime 'checkin-state.json'));Blocked=(Test-Path (Join-Path $Runtime 'blocked.json'));Queued=@(Get-ChildItem (Join-Path $Runtime 'queue') -Filter '*.json').Count} | Format-List
Get-ChildItem (Join-Path $Runtime 'logs') -Filter '*.jsonl' | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 2 | ForEach-Object {
    Write-Host "Log: $($_.Name)"
    Get-Content -LiteralPath $_.FullName -Tail 10
}
