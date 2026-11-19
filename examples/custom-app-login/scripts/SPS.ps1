#requires -Version 7.0
<#
    SPS 管理網頁 RemoteApp 自動登入（One Identity Safeguard）

    Launcher 命令列（與原 sps.ps1 相同，不需修改）：
      --cmd "C:\Program Files\PowerShell\7\pwsh.exe" --args "-File C:\custom\sps\sps.ps1 -username {username} -password {password} -asset {Target.AssetNetworkAddress}"

    相較原腳本的改進：
    1. 明確指定 Chrome 與 ChromeDriver 路徑（SOP 2.3 節）；找不到時記錄警告並
       退回模組預設行為，與原腳本相容。
    2. 以輪詢等待登入欄位出現，取代固定 Start-Sleep 2。
    3. 只結束本腳本啟動的 chromedriver，不影響主機上其他使用者的工作階段。
       Chrome 視窗保留給使用者繼續操作，與原腳本行為相同。
    4. 寫入階段日誌（不記錄密碼），RemoteApp 工作階段沒有主控台可看。
    5. -asset 已含 http(s):// 時不再重複補 scheme。

    憑證：預設沿用原腳本的 ignore-certificate-errors（SPS 多為自簽憑證）。
    SPS 換用受發佈主機信任的憑證後，可加 -VerifyCertificate 恢復憑證檢查。

    部署檢查（每次放置或搬移腳本都要核對相對位置）：
    - Launcher 命令列 -File 指向的路徑，必須是本腳本實際所在位置。
    - 日誌固定寫到 $LogPath，不隨腳本位置改變；日誌開頭會記錄「腳本位置」。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$username,
    [Parameter(Mandatory)][string]$password,
    [Parameter(Mandatory)][string]$asset,
    [string]$ChromePath = 'C:\Automation\chrome\chrome.exe',
    [switch]$VerifyCertificate,
    [int]$TimeoutSec = 30,
    [string]$LogPath = 'C:\custom\sps\sps.log'
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    try {
        $dir = Split-Path $LogPath -Parent
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        "[$(Get-Date -f 'yyyy-MM-dd HH:mm:ss')] $Message" | Out-File $LogPath -Append -Encoding UTF8
    } catch { }
}

trap {
    Write-Log "例外：$($_.Exception.Message)"
    Write-Log "堆疊：$($_.ScriptStackTrace)"
    break
}

Write-Log "=== 啟動 帳號=$env:USERNAME PS=$($PSVersionTable.PSVersion) 資產=$asset 登入=$username 驗證憑證=$($VerifyCertificate.IsPresent) ==="
Write-Log "腳本位置：$PSCommandPath"

# 組出登入網址；-asset 只填主機時補 https://
$url = if ($asset -match '^(?i)https?://') { $asset } else { "https://$asset" }
$uri = $null
if (-not [Uri]::TryCreate($url, [UriKind]::Absolute, [ref]$uri)) { throw "資產位址無法組成有效網址：$url" }
Write-Log "登入網址：$($uri.AbsoluteUri)"

Import-Module Selenium -ErrorAction Stop
$seCmd = Get-Command Start-SeDriver -ErrorAction Stop
Write-Log "Selenium 模組：$($seCmd.Module.Version) $($seCmd.Module.ModuleBase)"

# 參數寫法沿用原腳本，ChromeDriver 會自行補上 -- 前綴
$chromeArgs = @('start-maximized')
if (-not $VerifyCertificate) { $chromeArgs += 'ignore-certificate-errors' }

$startParams = @{
    Browser   = 'Chrome'
    Arguments = $chromeArgs
    StartURL  = $uri.AbsoluteUri
}

if ($ChromePath -and (Test-Path -LiteralPath $ChromePath -PathType Leaf)) {
    $startParams.BinaryPath = $ChromePath
    Write-Log "Chrome：$ChromePath（$((Get-Item $ChromePath).VersionInfo.ProductVersion)）"
} else {
    Write-Log "警告：找不到 $ChromePath，改由 Selenium 自行尋找 Chrome"
}

$driverDir = Join-Path $seCmd.Module.ModuleBase 'assemblies'
if (Test-Path -LiteralPath (Join-Path $driverDir 'chromedriver.exe') -PathType Leaf) {
    $startParams.WebDriverPath = $driverDir
    $driverVer = (& (Join-Path $driverDir 'chromedriver.exe') --version 2>$null) -join ' '
    Write-Log "ChromeDriver：$driverDir（$driverVer）"
} else {
    Write-Log "警告：模組 assemblies 內沒有 chromedriver.exe，改由 Selenium 自行尋找"
}

# 記下啟動前已存在的本程序子 chromedriver，之後只清理本次新增的
function Get-MyChromeDriver {
    @(Get-CimInstance Win32_Process -Filter "Name='chromedriver.exe' AND ParentProcessId=$PID" `
        -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessId)
}
$driverBefore = Get-MyChromeDriver

Start-SeDriver @startParams | Out-Null
Write-Log 'Start-SeDriver 完成'

# 輪詢等待元素出現；找不到時 Get-SeElement 可能丟例外或回傳空值，兩者都視為未出現
function Wait-SeElement {
    param([string]$By, [string]$Value, [string]$What, [int]$Sec = $TimeoutSec)
    $end = (Get-Date).AddSeconds($Sec)
    do {
        try {
            $el = Get-SeElement -By $By $Value -ErrorAction Stop
            if ($el) { return ($el | Select-Object -First 1) }
        } catch { }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $end)
    throw "逾時：$Sec 秒內等不到 $What（$By=$Value）"
}

$elementUser   = Wait-SeElement -By Id        -Value 'local-username' -What '帳號欄位'
$elementPasswd = Wait-SeElement -By Id        -Value 'local-password' -What '密碼欄位'
$elementClick  = Wait-SeElement -By ClassName -Value 'flat primary'   -What '登入按鈕'
Write-Log '登入欄位已出現'

Invoke-SeKeys -Element $elementUser -Keys $username
Write-Log "已填入帳號（$($username.Length) 字元）"
Invoke-SeKeys -Element $elementPasswd -Keys $password
Write-Log "已填入密碼（$($password.Length) 字元）"
$password = $null

Invoke-SeClick -Element $elementClick
Write-Log '已按下登入'

# 確認登入結果：帳號欄位消失視為已離開登入頁；仍在時只記錄，不中止
$left = $false
$end = (Get-Date).AddSeconds(10)
do {
    Start-Sleep -Milliseconds 500
    try {
        $still = Get-SeElement -By Id 'local-username' -ErrorAction Stop
        if (-not $still) { $left = $true }
    } catch { $left = $true }
} while (-not $left -and (Get-Date) -lt $end)
if ($left) { Write-Log '結果：已離開登入頁' }
else { Write-Log '結果：10 秒後仍停在登入頁，請確認帳密或頁面提示' }

# 只結束本腳本啟動的 chromedriver；Chrome 視窗保留給使用者
$driverNew = Get-MyChromeDriver | Where-Object { $_ -notin $driverBefore }
foreach ($id in $driverNew) {
    try {
        Stop-Process -Id $id -Force -ErrorAction Stop
        Write-Log "已結束本次啟動的 chromedriver（PID $id）"
    } catch {
        Write-Log "結束 chromedriver（PID $id）失敗：$($_.Exception.Message)"
    }
}
if (-not $driverNew) { Write-Log '警告：找不到本次啟動的 chromedriver，未做清理' }
