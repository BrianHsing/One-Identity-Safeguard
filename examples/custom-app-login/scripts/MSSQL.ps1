#requires -Version 5.1
<#
    SSMS 20.x RemoteApp 自動登入（One Identity Safeguard）

    介面字串繫結 SSMS 20.x 繁體中文版，換語言或升版必須同步修改 $UI。

    勾選框處理說明：
    SSMS 的「信任伺服器憑證」是 owner-draw CheckBox，BM_GETCHECK 讀不到
    真實狀態、BM_CLICK 無效、UIA SetFocus() 會被拒絕。本腳本改用兩種策略：
      策略 A：WM_COMMAND + BN_CLICKED 送到父視窗（不需搶前景，優先使用）
      策略 B：AttachThreadInput + SetFocus + 空白鍵（需搶前景，備援）
    因為無法讀取狀態，腳本先以 A 嘗試並按下連線；若出現憑證錯誤對話框，
    自動關閉後改用 B 重試一次。

    -ResetProfile 會在啟動前刪除 SqlStudio.bin，確保對話框回到已知初始
    狀態（勾選框未勾、驗證方式為預設），同時清掉伺服器 MRU。共用
    RemoteApp 主機建議啟用。

    其他限制：
    1. 微軟官方不支援多人同時在同一台機器使用 SSMS（含多工作階段主機）。
    2. -TrustServerCertificate 停用憑證驗證，連線仍加密但失去中間人防護。
       較乾淨的做法是將伺服器憑證匯入跳板機受信任根，必要時搭配
       -HostNameInCertificate。
    3. 全程記錄寫入 $LogPath，RemoteApp 工作階段沒有主控台可看。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$username,
    [Parameter(Mandatory)][string]$password,
    [Parameter(Mandatory)][string]$asset,
    [switch]$TrustServerCertificate,
    [string]$HostNameInCertificate,
    [switch]$ResetProfile,
    [int]$TimeoutSec = 120,
    [string]$LogPath = 'C:\custom\MSSQL\MSSQL.log'
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

Write-Log "=== 啟動 帳號=$env:USERNAME 資產=$asset 登入=$username 信任憑證=$($TrustServerCertificate.IsPresent) ==="

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

if (-not ('W' -as [type])) {
Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class W {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr SendMessage(IntPtr h, uint m, IntPtr w, string l);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr SendMessage(IntPtr h, uint m, IntPtr w, StringBuilder l);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SendMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr GetParent(IntPtr h);
    [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, IntPtr pid);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
}
'@
}

# SSMS 20.x 繁體中文版介面字串；換語言或升版必須同步修改
$UI = @{
    Dialog    = '連線至伺服器'
    Server    = '伺服器名稱(S):'
    Auth      = '驗證(A):'
    AuthSql   = 'SQL Server 驗證'
    Login     = '登入(L):'
    Password  = '密碼(P):'
    Connect   = '連線(C)'
    OptExpand = '選項(O) >>'
    Trust     = '信任伺服器憑證(U)'
    CertHost  = '憑證中的主機名稱(H):'
    OK        = '確定'
}

$WM_SETTEXT       = 0x000C
$WM_GETTEXTLENGTH = 0x000E
$WM_COMMAND       = 0x0111
$WM_KEYDOWN       = 0x0100
$WM_KEYUP         = 0x0101
$BM_CLICK         = 0x00F5
$VK_SPACE         = [IntPtr]0x20
$SW_RESTORE       = 9

$AE   = [System.Windows.Automation.AutomationElement]
$Desc = [System.Windows.Automation.TreeScope]::Descendants
$Walk = [System.Windows.Automation.TreeWalker]::ControlViewWalker

function Wait-For {
    param([scriptblock]$Probe, [int]$Sec, [string]$What)
    $end = (Get-Date).AddSeconds($Sec)
    do {
        $r = & $Probe
        if ($r) { return $r }
        Start-Sleep -Milliseconds 400
    } while ((Get-Date) -lt $end)
    throw "逾時：等不到 $What"
}

function Find-ByName {
    param($Parent, [string]$Name)
    $cond = New-Object System.Windows.Automation.PropertyCondition($AE::NameProperty, $Name)
    $Parent.FindFirst($Desc, $cond)
}

# FindFirst 取得的元素做 GetNextSibling 會回 null，
# 改為從父容器走訪一次，之後全部用座標配對
function Get-FieldMap {
    param($Dialog, [string]$AnchorLabel)
    $anchor = Find-ByName $Dialog $AnchorLabel
    if (-not $anchor) { return $null }
    $panel = $Walk.GetParent($anchor)
    if (-not $panel) { return $null }

    $items = @()
    $c = $Walk.GetFirstChild($panel)
    while ($c) {
        $items += [pscustomobject]@{
            El   = $c
            Name = $c.Current.Name
            Type = $c.Current.ControlType
            Rect = $c.Current.BoundingRectangle
        }
        $c = $Walk.GetNextSibling($c)
    }
    if ($items.Count -gt 0) { ,$items } else { $null }
}

# 標籤在左、輸入元素同一列且在右
function Get-InputFor {
    param($Items, [string]$LabelName)
    $lbl = $Items | Where-Object { $_.Name -eq $LabelName } | Select-Object -First 1
    if (-not $lbl) { throw "找不到標籤 $LabelName" }
    $hit = $Items |
        Where-Object { $_.Rect.X -gt $lbl.Rect.X -and [math]::Abs($_.Rect.Y - $lbl.Rect.Y) -le 6 } |
        Sort-Object { $_.Rect.X } | Select-Object -First 1
    if (-not $hit) { throw "找不到 $LabelName 對應的輸入欄位" }
    $hit.El
}

# ComboBox 的 Hwnd 不一定吃 WM_SETTEXT，降到底下的編輯子視窗
function Resolve-EditHandle {
    param($Element)
    if ($Element.Current.ControlType -eq [System.Windows.Automation.ControlType]::ComboBox) {
        $child = $Walk.GetFirstChild($Element)
        while ($child) {
            $ch = [IntPtr]$child.Current.NativeWindowHandle
            if ($ch -ne [IntPtr]::Zero -and
                $child.Current.ControlType -ne [System.Windows.Automation.ControlType]::Button) {
                return $ch
            }
            $child = $Walk.GetNextSibling($child)
        }
    }
    $h = [IntPtr]$Element.Current.NativeWindowHandle
    if ($h -eq [IntPtr]::Zero) { throw '目標欄位沒有視窗控制代碼' }
    $h
}

function Set-EditText {
    param($Element, [string]$Text, [string]$Label)
    $h = Resolve-EditHandle $Element
    [void][W]::SendMessage($h, $WM_SETTEXT, [IntPtr]::Zero, $Text)

    $len = [int][W]::SendMessage($h, $WM_GETTEXTLENGTH, [IntPtr]::Zero, [IntPtr]::Zero)
    if ($len -ne $Text.Length) { throw "$Label 寫入失敗（預期 $($Text.Length) 字元，實際 $len）" }
    Write-Log "已填入 $Label（$($Text.Length) 字元）"
}

# ValuePattern 只改顯示文字、不觸發 SelectedIndexChanged，必須真的挑選項。
# WinForms 下拉清單是獨立的最上層視窗，不在 ComboBox 子樹內；
# Select() 只標記選取，還要明確收合才會送出變更事件。
function Set-ComboValue {
    param($Element, [string]$Value, [string]$Label)

    $ep = $null
    if (-not $Element.TryGetCurrentPattern(
            [System.Windows.Automation.ExpandCollapsePattern]::Pattern, [ref]$ep)) {
        throw "$Label 無法設定（沒有 ExpandCollapsePattern）"
    }
    $ep.Expand()
    Start-Sleep -Milliseconds 600

    $pidCond  = New-Object System.Windows.Automation.PropertyCondition(
                   $AE::ProcessIdProperty, $Element.Current.ProcessId)
    $listCond = New-Object System.Windows.Automation.PropertyCondition(
                   $AE::ControlTypeProperty, [System.Windows.Automation.ControlType]::List)
    $andCond  = New-Object System.Windows.Automation.AndCondition($pidCond, $listCond)
    $nameCond = New-Object System.Windows.Automation.PropertyCondition($AE::NameProperty, $Value)

    $item = $null
    $deadline = (Get-Date).AddSeconds(10)
    while (-not $item -and (Get-Date) -lt $deadline) {
        foreach ($lst in $AE::RootElement.FindAll($Desc, $andCond)) {
            $hit = $lst.FindFirst($Desc, $nameCond)
            if ($hit) { $item = $hit; break }
        }
        if (-not $item) { Start-Sleep -Milliseconds 300 }
    }

    if (-not $item) {
        $dump = @()
        foreach ($lst in $AE::RootElement.FindAll($Desc, $andCond)) {
            $c = $Walk.GetFirstChild($lst)
            while ($c) { $dump += $c.Current.Name; $c = $Walk.GetNextSibling($c) }
        }
        $ep.Collapse()
        throw "$Label 找不到選項「$Value」；清單內容：$($dump -join ' | ')"
    }

    $sip = $null
    if (-not $item.TryGetCurrentPattern(
            [System.Windows.Automation.SelectionItemPattern]::Pattern, [ref]$sip)) {
        $ep.Collapse()
        throw "$Label 選項無法選取"
    }
    $sip.Select()
    Start-Sleep -Milliseconds 300

    if ($ep.Current.ExpandCollapseState -eq
        [System.Windows.Automation.ExpandCollapseState]::Expanded) {
        $ep.Collapse()
    }
    Start-Sleep -Milliseconds 600
    Write-Log "已設定 $Label = $Value"
}

# 策略 A：把 BN_CLICKED 通知直接送給父視窗，由 WinForms 反射回控制項，
# 會觸發 OnClick 進而翻轉 CheckState。不需要搶前景。
function Invoke-CheckBoxByCommand {
    param($Element)
    $eh = [IntPtr]$Element.Current.NativeWindowHandle
    if ($eh -eq [IntPtr]::Zero) { throw '勾選框沒有視窗控制代碼' }
    $parent = [W]::GetParent($eh)
    if ($parent -eq [IntPtr]::Zero) { throw '勾選框沒有父視窗' }
    $ctrlId = [W]::GetDlgCtrlID($eh)
    $wParam = [IntPtr]($ctrlId -band 0xFFFF)      # BN_CLICKED = 0，高位元為 0
    [void][W]::SendMessage($parent, $WM_COMMAND, $wParam, $eh)
    Start-Sleep -Milliseconds 400
    Write-Log "策略A：WM_COMMAND BN_CLICKED 已送出（ctrlId=$ctrlId）"
}

# 策略 B：接上 SSMS 的輸入佇列後設焦點再送空白鍵。需要搶前景。
function Invoke-CheckBoxByKey {
    param($Dialog, $Element)
    $dh = [IntPtr]$Dialog.Current.NativeWindowHandle
    $eh = [IntPtr]$Element.Current.NativeWindowHandle
    if ($eh -eq [IntPtr]::Zero) { throw '勾選框沒有視窗控制代碼' }

    $targetTid = [W]::GetWindowThreadProcessId($dh, [IntPtr]::Zero)
    $selfTid   = [W]::GetCurrentThreadId()
    $attached  = [W]::AttachThreadInput($selfTid, $targetTid, $true)
    try {
        [void][W]::ShowWindow($dh, $SW_RESTORE)
        [void][W]::SetForegroundWindow($dh)
        Start-Sleep -Milliseconds 400
        [void][W]::SetFocus($eh)
        Start-Sleep -Milliseconds 200
        [void][W]::SendMessage($eh, $WM_KEYDOWN, $VK_SPACE, [IntPtr]0)
        [void][W]::SendMessage($eh, $WM_KEYUP,   $VK_SPACE, [IntPtr]0)
        Start-Sleep -Milliseconds 400
    }
    finally {
        if ($attached) { [void][W]::AttachThreadInput($selfTid, $targetTid, $false) }
    }
    Write-Log "策略B：AttachThreadInput + 空白鍵已送出（attached=$attached）"
}

# 錯誤訊息方塊的標題與登入對話框同名，用是否含「確定」按鈕分辨
function Get-ErrorDialog {
    param($Main)
    $cond = New-Object System.Windows.Automation.PropertyCondition($AE::NameProperty, $UI.Dialog)
    foreach ($w in $Main.FindAll($Desc, $cond)) {
        try {
            if (Find-ByName $w $UI.OK) { return $w }
        } catch { }
    }
    $null
}

function Close-Dialog {
    param($Dialog)
    $ok = Find-ByName $Dialog $UI.OK
    if (-not $ok) { return }
    $ip = $null
    if ($ok.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$ip)) {
        $ip.Invoke()
    } else {
        [void][W]::SendMessage([IntPtr]$ok.Current.NativeWindowHandle,
                               $BM_CLICK, [IntPtr]::Zero, [IntPtr]::Zero)
    }
    Start-Sleep -Milliseconds 600
}

function Invoke-Connect {
    param($Dialog)
    $btn = Find-ByName $Dialog $UI.Connect
    if (-not $btn) { throw '找不到連線按鈕' }
    [void][W]::SendMessage([IntPtr]$btn.Current.NativeWindowHandle,
                           $BM_CLICK, [IntPtr]::Zero, [IntPtr]::Zero)
    Write-Log '已按下連線'
}

# 連線成功的判斷：登入對話框消失；失敗則出現含「確定」的錯誤方塊
function Wait-ConnectResult {
    param($Main, $Dialog, [int]$Sec = 40)
    $end = (Get-Date).AddSeconds($Sec)
    while ((Get-Date) -lt $end) {
        Start-Sleep -Milliseconds 700
        $err = Get-ErrorDialog $Main
        if ($err) { return @{ Result = 'Error'; Dialog = $err } }
        try {
            if (-not $Dialog.Current.IsOffscreen) {
                $still = Find-ByName $Main $UI.Dialog
                if (-not $still) { return @{ Result = 'Success' } }
            }
        } catch [System.Windows.Automation.ElementNotAvailableException] {
            return @{ Result = 'Success' }
        }
    }
    @{ Result = 'Timeout' }
}

if ($ResetProfile) {
    $bin = Join-Path $env:APPDATA 'Microsoft\SQL Server Management Studio\20.0\SqlStudio.bin'
    if (Test-Path $bin) {
        Remove-Item $bin -Force -ErrorAction SilentlyContinue
        Write-Log "已清除設定檔 $bin"
    }
}

$ssms = Get-ChildItem 'C:\Program Files (x86)\Microsoft SQL Server Management Studio 20',
                      'C:\Program Files\Microsoft SQL Server Management Studio 20' `
                      -Filter 'Ssms.exe' -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
if (-not $ssms) { throw '找不到 SSMS 20' }
Write-Log "SSMS 路徑：$ssms"

$proc = Start-Process $ssms -PassThru -ArgumentList '-nosplash'

$pidCond = New-Object System.Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $proc.Id)
$main = Wait-For -Sec $TimeoutSec -What 'SSMS 主視窗' -Probe {
    $AE::RootElement.FindFirst([System.Windows.Automation.TreeScope]::Children, $pidCond)
}
$dlg = Wait-For -Sec $TimeoutSec -What '連線對話框' -Probe { Find-ByName $main $UI.Dialog }
Write-Log '連線對話框已出現'

if ($TrustServerCertificate -or $HostNameInCertificate) {
    $optExpand = Find-ByName $dlg $UI.OptExpand
    if ($optExpand) {
        [void][W]::SendMessage([IntPtr]$optExpand.Current.NativeWindowHandle,
                               $BM_CLICK, [IntPtr]::Zero, [IntPtr]::Zero)
        Wait-For -Sec 10 -What '連線安全性區段' -Probe { Find-ByName $dlg $UI.Trust } | Out-Null
        Write-Log '已展開選項面板'
    } else {
        Write-Log '選項面板已是展開狀態'
    }
}

$fields = Wait-For -Sec 30 -What '登入欄位' -Probe { Get-FieldMap $dlg $UI.Password }

# 驗證方式必須先設定，否則登入與密碼欄位為停用狀態，寫不進去
Set-ComboValue (Get-InputFor $fields $UI.Auth) $UI.AuthSql '驗證方式'

# 切換驗證方式後 WinForms 會重建欄位，舊的 AutomationElement 與 Hwnd 失效
$fields = Wait-For -Sec 15 -What '切換後的登入欄位' -Probe {
    $m = Get-FieldMap $dlg $UI.Password
    if ($m -and ($m | Where-Object { $_.Name -eq $UI.Login })) { $m } else { $null }
}

Set-EditText (Get-InputFor $fields $UI.Server) $asset    '伺服器名稱'
Set-EditText (Get-InputFor $fields $UI.Login)  $username '登入名稱'

if ($HostNameInCertificate) {
    Set-EditText (Get-InputFor $fields $UI.CertHost) $HostNameInCertificate '憑證主機名稱'
}

$pwdElement = Get-InputFor $fields $UI.Password
Set-EditText $pwdElement $password '密碼'

if ($TrustServerCertificate) {
    $trust = Find-ByName $dlg $UI.Trust
    if (-not $trust) { throw '找不到信任伺服器憑證' }
    Invoke-CheckBoxByCommand $trust
}

Invoke-Connect $dlg
$r = Wait-ConnectResult -Main $main -Dialog $dlg

if ($r.Result -eq 'Error' -and $TrustServerCertificate) {
    Write-Log '第一次連線失敗，改用策略B重試'
    Close-Dialog $r.Dialog

    $fields = Wait-For -Sec 15 -What '重試用的登入欄位' -Probe { Get-FieldMap $dlg $UI.Password }
    Set-EditText (Get-InputFor $fields $UI.Password) $password '密碼（重試）'

    $trust = Find-ByName $dlg $UI.Trust
    if ($trust) { Invoke-CheckBoxByKey -Dialog $dlg -Element $trust }

    Invoke-Connect $dlg
    $r = Wait-ConnectResult -Main $main -Dialog $dlg
}

$password = $null
[System.GC]::Collect()

Write-Log "結果：$($r.Result)"
if ($r.Result -eq 'Error') {
    $detail = ''
    try {
        $txtCond = New-Object System.Windows.Automation.PropertyCondition(
                      $AE::ControlTypeProperty, [System.Windows.Automation.ControlType]::Text)
        $detail = ($r.Dialog.FindAll($Desc, $txtCond) |
                   ForEach-Object { $_.Current.Name } | Where-Object { $_ }) -join ' / '
    } catch { }
    Write-Log "錯誤內容：$detail"
}