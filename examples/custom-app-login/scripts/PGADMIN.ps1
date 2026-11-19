#requires -Version 5.1
<#
    pgAdmin 4 桌面版 RemoteApp 自動登入 PostgreSQL（One Identity Safeguard）

    Launcher 命令列：
      --cmd "C:\Program Files\PowerShell\7\pwsh.exe" --args "-File C:\custom\pgadmin\pgadmin.ps1 -username {username} -password {password} -asset {Target.AssetNetworkAddress}"

    流程：
    1. 結束本工作階段已開啟的 pgAdmin（其他使用者的工作階段不受影響）。
    2. 以 pgAdmin 內附 Python 執行 setup.py load-servers，將資產登錄為伺服器
       （只寫主機、埠、資料庫與帳號，不寫密碼）。預設加 --replace，
       會清掉此 Windows 帳戶 pgAdmin 裡原有的伺服器清單，讓每次都從已知狀態開始；
       加 -KeepServers 可保留原清單（重複執行會出現重複項目）。
    3. 啟動 pgAdmin4.exe（加 --force-renderer-accessibility 讓 UI Automation 看得到
       Electron 內的網頁元素；加 --disable-gpu 避免 RemoteApp 黑畫面）。
    4. 雙擊物件樹的「Servers」展開；pgAdmin 會自動對唯一的伺服器跳出連線對話框，
       沒跳出時再展開伺服器節點。
    5. 確認未勾選儲存密碼，以 SendInput Unicode 輸入密碼後按 OK。
    6. 連線對話框關閉即判定成功；失敗時記錄錯誤並把對話框留給使用者。日誌不記錄密碼。

    pgAdmin 9.x 的 UI Automation 特性（2026-11-19 以 9.19 實測）：
    - 頂層視窗從 UIA 根節點列舉不到，須以 Win32 EnumWindows 找到後再轉成 UIA 元素。
    - 物件樹節點只露出 Text 元素，沒有 TreeItem 與展開模式，收合中的節點沒有座標。
    - 物件樹節點對右方向鍵沒有反應，須雙擊展開。
    - OK 按鈕名稱前有圖示字元（實際為「 OK」），須以正規比對。

    限制：
    - pgAdmin 桌面版是 Electron 應用，介面元素名稱隨版本與語言變動。
      第一次部署或升版後請加 -DumpTree，把 UI Automation 樹寫入日誌以便調整。
    - 以滑鼠與鍵盤事件操作，執行期間不要操作滑鼠鍵盤。密碼以 Unicode 字元碼送出，
      不受 CapsLock 與中文輸入法影響；不使用剪貼簿，避免經 RemoteApp 同步到使用者端。
    - 本檔須以 UTF-8 with BOM 儲存，Windows PowerShell 5.1 才能正確讀取中文字串。

    部署檢查（每次放置或搬移腳本都要核對相對位置）：
    - Launcher 命令列 -File 指向的路徑，必須是本腳本實際所在位置。
    - 日誌固定寫到 $LogPath，不隨腳本位置改變；日誌開頭會記錄「腳本位置」。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$username,
    [Parameter(Mandatory)][string]$password,
    [Parameter(Mandatory)][string]$asset,
    [int]$Port = 5432,
    [string]$Database = 'postgres',
    [string]$SSLMode = 'prefer',
    [string]$ServerName,
    [string]$PgAdminPath = 'C:\Program Files\pgAdmin 4\runtime\pgAdmin4.exe',
    [switch]$KeepServers,
    [switch]$DumpTree,
    [switch]$EnableGpu,
    [switch]$NoMaximize,
    [int]$TimeoutSec = 120,
    [string]$LogPath = 'C:\custom\pgadmin\pgadmin.log'
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

# 解析主機與埠：-asset 可為 host 或 host:port（IPv6 請用 -Port 另外指定）
$pgHost = $asset
if ($asset -match '^([^:]+):(\d+)$') { $pgHost = $Matches[1]; $Port = [int]$Matches[2] }
if (-not $ServerName) { $ServerName = $pgHost }

Write-Log "=== 啟動 帳號=$env:USERNAME PS=$($PSVersionTable.PSVersion) 資產=$asset 主機=${pgHost}:$Port 資料庫=$Database 登入=$username ==="
Write-Log "腳本位置：$PSCommandPath"

# 介面字串（英文與繁中）；升版或換語言時依 -DumpTree 結果調整
$UI = @{
    SaveWords  = @('Save Password', 'Save password', '儲存密碼', '保存密碼')
}

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

if (-not ('PgW' -as [type])) {
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class PgW {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr h);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hgt, bool repaint);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int n);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int n);
    // 以 Win32 列舉指定程序的所有頂層視窗（含隱藏），不依賴 UI Automation
    public static System.Collections.Generic.List<IntPtr> TopWindows(uint[] pids) {
        var list = new System.Collections.Generic.List<IntPtr>();
        EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p); if (Array.IndexOf(pids, p) >= 0) list.Add(h); return true; }, IntPtr.Zero);
        return list;
    }
    public static string Describe(IntPtr h) {
        var t = new System.Text.StringBuilder(256); var c = new System.Text.StringBuilder(256);
        GetWindowText(h, t, 256); GetClassName(h, c, 256); uint p; GetWindowThreadProcessId(h, out p);
        return String.Format("0x{0:X} pid={1} visible={2} class=[{3}] title=[{4}]", h.ToInt64(), p, IsWindowVisible(h), c, t);
    }
    [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx, dy; public uint mouseData, dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT { public ushort wVk, wScan; public uint dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Explicit)] public struct INPUTUNION { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
    [StructLayout(LayoutKind.Sequential)] public struct INPUT { public uint type; public INPUTUNION u; }
    [DllImport("user32.dll", SetLastError = true)] public static extern uint SendInput(uint n, INPUT[] inputs, int size);
    // 以 Unicode 字元碼逐字輸入，回傳成功送出的事件數（每字 2 個：按下＋放開）
    public static int TypeText(string s) {
        int total = 0;
        foreach (char ch in s) {
            var arr = new INPUT[2];
            arr[0].type = 1; arr[0].u.ki.wScan = ch; arr[0].u.ki.dwFlags = 0x0004;
            arr[1].type = 1; arr[1].u.ki.wScan = ch; arr[1].u.ki.dwFlags = 0x0004 | 0x0002;
            total += (int)SendInput(2, arr, Marshal.SizeOf(typeof(INPUT)));
            System.Threading.Thread.Sleep(15);
        }
        return total;
    }
    public static void Click(int x, int y, int times) {
        SetCursorPos(x, y);
        for (int i = 0; i < times; i++) { mouse_event(0x02, 0, 0, 0, UIntPtr.Zero); mouse_event(0x04, 0, 0, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(60); }
    }
}
'@
}

$AE   = [System.Windows.Automation.AutomationElement]
$CT   = [System.Windows.Automation.ControlType]
$Desc = [System.Windows.Automation.TreeScope]::Descendants
$All  = [System.Windows.Automation.Condition]::TrueCondition

function Wait-For {
    param([scriptblock]$Probe, [int]$Sec, [string]$What)
    $end = (Get-Date).AddSeconds($Sec)
    do {
        $r = & $Probe
        if ($r) { return $r }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $end)
    throw "逾時：$Sec 秒內等不到 $What"
}

# ---------- 1. 找到 pgAdmin 安裝位置 ----------
if (-not (Test-Path -LiteralPath $PgAdminPath -PathType Leaf)) {
    $found = Get-ChildItem 'C:\Program Files\pgAdmin 4' -Recurse -Filter 'pgAdmin4.exe' -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq 'runtime' } | Select-Object -First 1
    if (-not $found) { throw "找不到 pgAdmin4.exe（$PgAdminPath）" }
    Write-Log "警告：$PgAdminPath 不存在，改用 $($found.FullName)"
    $PgAdminPath = $found.FullName
}
$root   = Split-Path (Split-Path $PgAdminPath -Parent) -Parent
$python = Join-Path $root 'python\python.exe'
$setup  = Join-Path $root 'web\setup.py'
Write-Log "pgAdmin：$PgAdminPath（$((Get-Item $PgAdminPath).VersionInfo.ProductVersion)）"

# ---------- 2. 結束本工作階段的 pgAdmin ----------
$mySession = (Get-Process -Id $PID).SessionId
$rootPattern = [regex]::Escape($root)
$old = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.SessionId -eq $mySession -and $_.ExecutablePath -and $_.ExecutablePath -match "^$rootPattern"
}
foreach ($p in $old) {
    try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Write-Log "已結束本工作階段的 $($p.Name)（PID $($p.ProcessId)）" } catch { }
}
if ($old) { Start-Sleep -Seconds 2 }

# ---------- 3. 登錄伺服器（不含密碼） ----------
$json = Join-Path $env:TEMP ("pgadmin-servers-{0}.json" -f [guid]::NewGuid().ToString('N'))
try {
    $def = [ordered]@{ Servers = [ordered]@{ '1' = [ordered]@{
        Name          = $ServerName
        Group         = 'Servers'
        Host          = $pgHost
        Port          = $Port
        MaintenanceDB = $Database
        Username      = $username
        SSLMode       = $SSLMode
    } } }
    $def | ConvertTo-Json -Depth 5 | Out-File $json -Encoding ascii

    $env:PGADMIN_SERVER_MODE = 'OFF'     # 桌面模式，寫入此 Windows 帳戶的 %APPDATA%\pgAdmin
    $env:PYTHONIOENCODING    = 'utf-8'

    # pgAdmin 桌面版啟動 Python 時會把 libpq.dll 所在目錄加入 PATH；
    # 直接呼叫 setup.py 須自行補上，否則 psycopg 載入失敗（no pq wrapper available）
    $libpq = Get-ChildItem $root -Recurse -Filter 'libpq.dll' -ErrorAction SilentlyContinue | Select-Object -First 1
    $dllDir = if ($libpq) { $libpq.DirectoryName } else { Join-Path $root 'runtime' }
    $env:PATH = "$dllDir;$env:PATH"
    Write-Log "libpq：$(if ($libpq) { $libpq.FullName } else { "找不到 libpq.dll，改將 $dllDir 加入 PATH" })"
    # 必須是陣列：單一字串展開（@var）時會被拆成逐字元參數
    [string[]]$extra = @()
    if (-not $KeepServers) { $extra += '--replace' }

    # Python 以 UTF-8 輸出；PowerShell 依 [Console]::OutputEncoding 解碼，
    # 中文 Windows 預設 CP950，不改會讓錯誤訊息與框線變成問號亂碼
    $prevEnc = [Console]::OutputEncoding
    $env:NO_COLOR = '1'
    try {
        [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
        # pgAdmin 7 以後為子命令語法；只有確定是舊版（不認得子命令）才改用 --load-servers
        $out = & $python $setup load-servers $json @extra 2>&1
        $code = $LASTEXITCODE
        if ($code -ne 0 -and ($out | Out-String) -match 'No such command|invalid choice|unrecognized arguments') {
            Write-Log "load-servers（新語法）結束碼 $code：$(($out | Out-String).Trim())"
            $out = & $python $setup --load-servers $json @extra 2>&1
            $code = $LASTEXITCODE
        }
    } finally {
        [Console]::OutputEncoding = $prevEnc
    }
    Write-Log "load-servers 結束碼 $code：$(($out | Out-String).Trim())"
    if ($code -ne 0) { throw '無法登錄伺服器，請檢查上方 setup.py 輸出' }
} finally {
    Remove-Item $json -Force -ErrorAction SilentlyContinue
}

# ---------- 4. 啟動 pgAdmin ----------
# RemoteApp 工作階段裡 Electron 的 GPU 繪製常造成黑畫面，預設停用 GPU；加 -EnableGpu 可恢復
$pgArgs = @('--force-renderer-accessibility')
if (-not $EnableGpu) { $pgArgs += '--disable-gpu', '--disable-gpu-compositing' }
# 清掉只給 setup.py 用的環境變數，讓 pgAdmin 以一般方式啟動
foreach ($v in 'PGADMIN_SERVER_MODE', 'PYTHONIOENCODING', 'NO_COLOR') { Remove-Item "Env:$v" -ErrorAction SilentlyContinue }
$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -and $_ -ne $dllDir }) -join ';'
$launchTime = Get-Date
$proc = Start-Process -FilePath $PgAdminPath -ArgumentList $pgArgs -WorkingDirectory (Split-Path $PgAdminPath -Parent) -PassThru
Write-Log "已啟動 pgAdmin（PID $($proc.Id)）參數：$($pgArgs -join ' ')"

function Get-PgProcs {
    @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.SessionId -eq $mySession -and $_.ExecutablePath -and $_.ExecutablePath -match "^$rootPattern"
    })
}

# 逾時時把 pgAdmin 自己的日誌尾端抄進來，判斷是啟動失敗還是視窗問題
function Write-PgDiag {
    $procs = Get-PgProcs
    Write-Log "診斷：主程序 PID $($proc.Id) 已結束=$($proc.HasExited)$(if ($proc.HasExited) { " 結束碼=$($proc.ExitCode)" })"
    Write-Log "診斷：本工作階段 pgAdmin 相關程序 $($procs.Count) 個：$(($procs | ForEach-Object { "$($_.Name)#$($_.ProcessId)" }) -join ' ')"
    foreach ($p in $procs) { Write-Log "    $($p.Name)#$($p.ProcessId) 父=$($p.ParentProcessId) $($p.CommandLine)" }
    Write-PgWin32
    $logs = foreach ($d in "$env:APPDATA\pgadmin4", "$env:APPDATA\pgAdmin", "$env:LOCALAPPDATA\pgadmin4") {
        Get-ChildItem $d -Filter '*.log' -Recurse -ErrorAction SilentlyContinue
    }
    foreach ($f in ($logs | Sort-Object LastWriteTime -Descending | Select-Object -First 3)) {
        Write-Log "診斷：$($f.FullName)（$($f.LastWriteTime)）最後 30 行："
        Get-Content $f.FullName -Tail 30 -ErrorAction SilentlyContinue | ForEach-Object { Write-Log "    $_" }
    }
    if (-not $logs) { Write-Log '診斷：找不到 pgAdmin 日誌' }
}

function Get-PgWindows {
    $ids = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.SessionId -eq $mySession -and $_.Name -eq 'pgAdmin4.exe'
    } | Select-Object -ExpandProperty ProcessId)
    if (-not $ids) { return @() }
    # 用 Win32 找可見的頂層視窗，再轉成 UIA 元素
    foreach ($h in [PgW]::TopWindows([uint32[]]$ids)) {
        if (-not [PgW]::IsWindowVisible($h)) { continue }
        try { $AE::FromHandle($h) } catch { }
    }
}

function Write-PgWin32 {
    $ids = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.SessionId -eq $mySession -and $_.Name -eq 'pgAdmin4.exe'
    } | Select-Object -ExpandProperty ProcessId)
    $hs = if ($ids) { [PgW]::TopWindows([uint32[]]$ids) } else { @() }
    Write-Log "  Win32 頂層視窗 $(@($hs).Count) 個（pgAdmin4.exe PID：$($ids -join ',')）"
    foreach ($h in $hs) { Write-Log "    $([PgW]::Describe($h))" }
}

function Find-InPg {
    param([scriptblock]$Match)
    foreach ($w in Get-PgWindows) {
        foreach ($e in $w.FindAll($Desc, $All)) {
            try { if (& $Match $e) { return $e } } catch { }
        }
    }
    return $null
}

function Write-Tree {
    param([string]$Stage)
    if (-not $DumpTree) { return }
    Write-Log "--- UIA 樹（$Stage）---"
    foreach ($w in Get-PgWindows) {
        Write-Log "視窗：[$($w.Current.Name)] Handle=$($w.Current.NativeWindowHandle)"
        $n = 0
        foreach ($e in $w.FindAll($Desc, $All)) {
            $c = $e.Current
            if (-not $c.Name -and -not $c.AutomationId -and -not $c.IsPassword) { continue }
            Write-Log ("  {0} | Name=[{1}] Id=[{2}] Pwd={3} Enabled={4}" -f $c.ControlType.ProgrammaticName, $c.Name, $c.AutomationId, $c.IsPassword, $c.IsEnabled)
            if (++$n -ge 400) { Write-Log '  ...（超過 400 項，截斷）'; break }
        }
    }
}

function Invoke-ElementClick {
    param($Element, [int]$Times = 1)
    $r = $Element.Current.BoundingRectangle
    if ($r.IsEmpty) { return $false }
    [PgW]::Click([int]($r.X + $r.Width / 2), [int]($r.Y + $r.Height / 2), $Times)
    return $true
}

$script:lastWinLog = Get-Date
$main = try { Wait-For -Sec $TimeoutSec -What 'pgAdmin 主視窗' -Probe {
    $wins = @(Get-PgWindows)
    if (((Get-Date) - $script:lastWinLog).TotalSeconds -ge 10) {
        $script:lastWinLog = Get-Date
        Write-Log "等待主視窗中，程序 $((Get-PgProcs).Count) 個，視窗：$(if ($wins) { ($wins | ForEach-Object { "[$($_.Current.Name)]" }) -join ' ' } else { '（無）' })"
        Write-PgWin32
    }
    $wins | Where-Object { $_.Current.Name -match 'pgAdmin' } | Select-Object -First 1
}
} catch { Write-PgDiag; throw }
$script:hwnd = [IntPtr]$main.Current.NativeWindowHandle
# Electron 在介面載入完成後會套用上次的視窗大小，太早最大化會被蓋掉，
# 所以這裡先最大化一次，物件樹載入後與登入結束時再各做一次。
# pgAdmin 先顯示載入視窗，介面載入後才是真正的主視窗（不同 handle）。
# 最大化前重新找出含物件樹工具列的視窗，避免對已關閉的載入視窗下指令。
function Update-MainHwnd {
    $cond = [System.Windows.Automation.PropertyCondition]::new($AE::AutomationIdProperty, 'filter-objects')
    foreach ($w in Get-PgWindows) {
        try {
            if ($w.FindFirst($Desc, $cond)) {
                $h = [IntPtr]$w.Current.NativeWindowHandle
                if ($h -ne $script:hwnd) { Write-Log "主視窗 handle 由 $($script:hwnd) 改為 $h"; $script:hwnd = $h }
                return
            }
        } catch { }
    }
}

function Set-PgMaximized {
    param([string]$Stage)
    if ($NoMaximize) { return }
    # 先送 WM_SYSCOMMAND/SC_MAXIMIZE（等同按標題列最大化鈕），沒生效再以 ShowWindow 補；
    # 仍不行就把視窗調成所在螢幕的工作區大小
    [PgW]::PostMessage($script:hwnd, 0x0112, [IntPtr]0xF030, [IntPtr]::Zero) | Out-Null
    Start-Sleep -Milliseconds 500
    if (-not [PgW]::IsZoomed($script:hwnd)) {
        [PgW]::ShowWindow($script:hwnd, 3) | Out-Null
        Start-Sleep -Milliseconds 300
    }
    if ([PgW]::IsZoomed($script:hwnd)) { Write-Log "最大化（$Stage）：成功"; return }
    $wa = [System.Windows.Forms.Screen]::FromHandle($script:hwnd).WorkingArea
    [PgW]::MoveWindow($script:hwnd, $wa.X, $wa.Y, $wa.Width, $wa.Height, $true) | Out-Null
    Write-Log "最大化（$Stage）：未生效，改調整為工作區大小 $($wa.Width)x$($wa.Height)"
}Set-PgMaximized '主視窗出現'
[PgW]::SetForegroundWindow($script:hwnd) | Out-Null
Write-Log "主視窗：[$($main.Current.Name)]"

# ---------- 5. 在物件樹找到伺服器並展開 ----------
# pgAdmin 9 的物件樹列通常不會出現在 UIA 樹裡（實測只有約 97 個元素，不含樹節點），
# 所以不等伺服器文字，改等物件樹工具列的「Filter Objects」按鈕出現，代表介面已載入。
$panel = try { Wait-For -Sec $TimeoutSec -What '物件樹工具列（filter-objects）' -Probe {
    Find-InPg { param($e) $e.Current.AutomationId -eq 'filter-objects' -and $e.Current.BoundingRectangle.Width -gt 0 }
} } catch { Write-Tree '等不到物件樹'; throw }
Write-Log "物件樹已載入：filter-objects 位置=$($panel.Current.BoundingRectangle)"
Update-MainHwnd
Set-PgMaximized '物件樹載入'
Start-Sleep -Seconds 2      # 讓伺服器清單載入
Write-Tree '物件樹已載入'

function Find-PasswordBox { Find-InPg { param($e) $e.Current.IsPassword -and $e.Current.IsEnabled } }

# pgAdmin 9 的物件樹在 UIA 中只露出文字元素（ControlType.Text），沒有 TreeItem 與展開模式。
# 收合中的子節點仍在樹裡但沒有座標，所以要先展開「Servers」群組，伺服器節點才點得到。
# 展開方式：點選節點文字後按右方向鍵；無效再改雙擊。
function Test-Shown { param($e) try { $r = $e.Current.BoundingRectangle; -not $r.IsEmpty -and $r.Width -gt 0 } catch { $false } }
function Find-Server { Find-InPg { param($e) $e.Current.ControlType -eq $CT::Text -and $e.Current.Name.Trim() -eq $ServerName -and (Test-Shown $e) } }

function Open-Node {
    param($Node, [string]$What, [scriptblock]$Done, [int]$Sec = 5, [string[]]$Order = @('right', 'double'))
    foreach ($how in $Order) {
        [PgW]::SetForegroundWindow($script:hwnd) | Out-Null
        if ($how -eq 'right') {
            Invoke-ElementClick $Node 1 | Out-Null
            Start-Sleep -Milliseconds 300
            [System.Windows.Forms.SendKeys]::SendWait('{RIGHT}')
        } else {
            Invoke-ElementClick $Node 2 | Out-Null
        }
        Write-Log "已對 [$What] 送出展開（$(if ($how -eq 'right') { '點選＋右方向鍵' } else { '雙擊' })）"
        try { return (Wait-For -Sec $Sec -What "$What 展開" -Probe $Done) } catch { }
    }
    return $null
}

[PgW]::SetForegroundWindow($script:hwnd) | Out-Null
$pwdBox = $null
$shownServer = Find-Server
if (-not $shownServer) {
    $group = $null
    try {
        $group = Wait-For -Sec 5 -What '物件樹的 Servers 群組' -Probe {
            Find-InPg { param($e) $e.Current.Name -match '^(Servers|伺服器|服务器)' -and (Test-Shown $e) }
        }
    } catch { }
    if ($group) {
        Write-Log "伺服器節點收合中，先展開群組 [$($group.Current.Name)]"
        $r = Open-Node $group $group.Current.Name { $pb = Find-PasswordBox; if ($pb) { $pb } else { Find-Server } } -Order 'double', 'right'
        if ($r -and $r.Current.IsPassword) { $pwdBox = $r; Write-Log '展開 Servers 後 pgAdmin 已自動跳出連線對話框' } else { $shownServer = $r }
    } else {
        # UIA 看不到 Servers 列時，以「Filter Objects」按鈕定位：物件樹第一列在工具列正下方
        $btn = Find-InPg { param($e) $e.Current.AutomationId -eq 'filter-objects' -and (Test-Shown $e) }
        if (-not $btn) { Write-Tree '找不到 Servers 與 filter-objects'; throw '無法定位物件樹' }
        $b = $btn.Current.BoundingRectangle
        $x = [int]($b.X + $b.Width * 2.5); $y = [int]($b.Bottom + $b.Height * 0.95)
        Write-Log "UIA 看不到 Servers 列，以 filter-objects 按鈕（$b）推算第一列位置 ($x,$y)"
        [PgW]::SetForegroundWindow($script:hwnd) | Out-Null
        [PgW]::Click($x, $y, 2)                                   # 雙擊展開 Servers（實測右方向鍵無效）
        Write-Log '已雙擊第一列展開 Servers'
        try { $r = Wait-For -Sec 5 -What '伺服器節點' -Probe { $pb = Find-PasswordBox; if ($pb) { $pb } else { Find-Server } } } catch { $r = $null }
        if ($r -and $r.Current.IsPassword) { $pwdBox = $r } else { $shownServer = $r }
        if (-not $shownServer -and -not $pwdBox) {
            # 仍看不到就全用鍵盤：往下一列到伺服器（--replace 後只有一台），再按右方向鍵連線
            [System.Windows.Forms.SendKeys]::SendWait('{DOWN}')
            Start-Sleep -Milliseconds 300
            [System.Windows.Forms.SendKeys]::SendWait('{RIGHT}')
            Write-Log '看不到伺服器節點，改以鍵盤下移一列後按右方向鍵'
            try { $pwdBox = Wait-For -Sec 10 -What '密碼對話框' -Probe { Find-PasswordBox } } catch { }
            if (-not $pwdBox) { Write-Tree '鍵盤展開後仍無密碼對話框'; throw '以鍵盤展開伺服器後沒有出現密碼對話框' }
        }
    }
}
if (-not $pwdBox) {
    if (-not $shownServer) { Write-Tree '展開 Servers 失敗'; throw "展開 Servers 後仍看不到伺服器 [$ServerName]" }
    Write-Log "伺服器節點已可見：[$($shownServer.Current.Name)] 位置=$($shownServer.Current.BoundingRectangle)"
    $pwdBox = Open-Node $shownServer $ServerName { Find-PasswordBox } 10
    if (-not $pwdBox) { Write-Tree '等不到密碼對話框'; throw '展開伺服器後沒有出現密碼對話框' }
}
Write-Log "密碼對話框已出現：Name=[$($pwdBox.Current.Name)]"
Write-Tree '密碼對話框'

# ---------- 6. 輸入密碼 ----------
$saveBox = Find-InPg { param($e)
    $n = $e.Current.Name
    ($UI.SaveWords | Where-Object { $n -like "*$_*" }) -and
    ($e.Current.ControlType -eq $CT::CheckBox -or $e.Current.ControlType -eq $CT::Button)
}
if ($saveBox) {
    try {
        $tp = $saveBox.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern)
        if ($tp.Current.ToggleState -eq [System.Windows.Automation.ToggleState]::On) {
            $tp.Toggle(); Write-Log '已取消勾選儲存密碼'
        } else { Write-Log '儲存密碼未勾選' }
    } catch { Write-Log "無法讀取儲存密碼勾選狀態：$($_.Exception.Message)" }
} else {
    Write-Log '警告：找不到儲存密碼勾選框（不影響登入）'
}

# 以 SendInput + KEYEVENTF_UNICODE 逐字送出：直接送字元碼，不受 CapsLock、
# 中文輸入法與鍵盤配置影響（SendKeys 送的是按鍵，會被這些狀態改變）。
# 不用剪貼簿，避免 RemoteApp 剪貼簿重新導向把密碼同步到使用者端。
[PgW]::SetForegroundWindow($script:hwnd) | Out-Null
Invoke-ElementClick $pwdBox 1 | Out-Null
try { $pwdBox.SetFocus() } catch { }
Start-Sleep -Milliseconds 300
[System.Windows.Forms.SendKeys]::SendWait('^a{DEL}')
$sent = [PgW]::TypeText($password)
Write-Log "已輸入密碼（$($password.Length) 字元，SendInput 送出 $sent 個事件，預期 $($password.Length * 2)）"
$password = $null

$okBtn = Find-InPg { param($e)
    $e.Current.ControlType -eq $CT::Button -and $e.Current.IsEnabled -and ($e.Current.Name -match '(^|\W)(OK|確定|确定)\s*$')
}
if ($okBtn) {
    try { $okBtn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke() }
    catch { Invoke-ElementClick $okBtn 1 | Out-Null }
    Write-Log "已按下 [$($okBtn.Current.Name)]"
} else {
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
    Write-Log '找不到 OK 按鈕，改送 Enter'
}

# ---------- 7. 確認結果 ----------
# 物件樹節點不在 UIA 樹裡，改以對話框判斷：
# 密碼框消失 = pgAdmin 已關閉對話框（只有連線成功才會關閉）；
# 密碼框仍在且出現 connection failed 等訊息 = 失敗，對話框留給使用者處理。
$result = $null
$end = (Get-Date).AddSeconds(30)
do {
    Start-Sleep -Milliseconds 700
    if (-not (Find-PasswordBox)) { $result = 'ok'; break }
    $err = Find-InPg { param($e) $e.Current.Name -match 'connection failed|FATAL|failed:' -and $e.Current.Name.Length -lt 1000 }
    if ($err) { $result = "錯誤：$($err.Current.Name)"; break }
} while ((Get-Date) -lt $end)

Update-MainHwnd
Set-PgMaximized '登入結束'
if ($result -eq 'ok') { Write-Log '結果：連線成功（連線對話框已關閉）' }
elseif ($result) { Write-Log "結果：$result"; Write-Log '（錯誤中的中文若為亂碼，是 PostgreSQL 以 Big5 回傳訊息；可將伺服器 lc_messages 設為 English 取得英文訊息）' }
else { Write-Log '結果：30 秒內無法確認連線狀態，請檢查畫面'; Write-Tree '結果不明' }
