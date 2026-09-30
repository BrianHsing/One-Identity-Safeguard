# KB-003：RemoteApp 搭配 PowerShell Selenium 客製化應用程式代登

## 方法與證據來源

本篇整理使用者既有做法：透過 Safeguard 的應用程式工作階段，在應用程式發佈主機啟動 PowerShell，帶入帳號、密碼與資產位址，再由 Selenium 開啟瀏覽器、填寫登入表單。發佈主機的套件與 16 支 PS1 已保存於 [代登範例目錄](../../examples/custom-app-login/README.md)。本次只讀取、盤點及做語法檢查，沒有安裝元件或操作客戶系統。

![使用者提供的 Remote Application Publisher 設定](../../images/kb/custom-app-login/remote-application-publisher.png)

原圖標題為 Remote Application Publisher 1.0.3.48455，顯示 11 筆已發佈項目；它證明設定方式，不代表每筆皆登入成功。Fortigate／FortigateSW 的右側命令列遭畫面裁切，不能據此重建完整字串。圖中 `{username}`、`{password}` 是原設定的替代欄位，不是實際帳密。

## 套件與版本

| 元件 | 本次保存內容 | 判讀 |
|---|---|---|
| PowerShell | `PowerShell-7.4.6-win-x64.msi` | 來源環境的 x64 安裝檔，不是要求新環境固定使用舊修補版 |
| PowerShell Selenium 模組 | `selenium.4.0.0-preview3.nupkg` | nuspec 為 4.0.0-preview3；psd1 ModuleVersion 為 4.0.0、Prerelease 為 preview3 |
| 已整理的模組資料夾 | `selenium.zip` | 包含 selenium 根目錄與 assemblies；ChromeDriver 與 NUPKG 內版本不同 |
| Google Chrome Dev | 使用者說明為現場瀏覽器 | 本次來源沒有瀏覽器安裝檔，也沒有完整版本證據 |
| ChromeDriver | 兩個 Selenium 套件均內含 | 不可因 ZIP 名稱相似而視為同一個 driver |
| 配置參考 | `模組.png`、`更新driver.png`、`pwsh.txt` | 保留原始資料；文字檔的 debug 參數不作預設建議 |

此處「Selenium 4.0」指 PowerShell Gallery 的 Selenium 4.0.0-preview3 模組，不應直接推論為 Selenium .NET／Java SDK 的同版相容性聲明。[模組發佈資料](https://www.powershellgallery.com/packages/Selenium/4.0.0-preview3)明列它是預覽版本。

使用者的做法是讓 Chrome Dev 與 ChromeDriver 配套。Google 官方說明：Chrome 115 起可使用 Chrome for Testing 提供的成對版本，既有非 CfT Chrome 則依版本選擇流程找相容 driver。版本相容仍不能保證網站 XPath、模組 API、TLS 或驗證流程相容。[Google 官方版本選擇](https://developer.chrome.com/docs/chromedriver/downloads/version-selection)。

### ZIP 內既有雜湊不一致

本次直接計算壓縮檔內的 ChromeDriver 位元組，未執行該 EXE：

| 套件 | chromedriver.exe SHA-256 |
|---|---|
| NUPKG | `c6131a3106a8956702459673bdcc7f37bdd8989a141d2cbe15dc0157f0d53c74` |
| ZIP | `ba21fb58c0be6963b7dba8efdfa8b772b014b2fa3c455f6328101f2ae883859a` |

ZIP 中附帶的 `chromedriver.exe.sha256` 仍為 NUPKG 的雜湊，與 ZIP 實際 driver 不符。這與曾更換 driver 的操作相容，但不是來源可信度驗證；部署前另核對原廠來源、實際版本及檔案雜湊，不直接採信舊 sidecar。兩個來源套件原樣保存，不覆寫成相同內容。

## 發佈主機準備

以 Windows PowerShell 7 x64 為網頁腳本的目標環境；先確認 RDS／RemoteApp、SPP／SPS 與應用程式啟動整合已依客戶設計完成。實際發佈及整合參考 [RemoteApp SOP](../sop/remoteapp-integration.md)。

將經核准的 PowerShell 與 Chrome Dev 安裝於發佈主機，再將模組放到所有執行帳戶可讀取、PowerShell 可探索的位置。原圖使用 `C:\Program Files\PowerShell\7\Modules\selenium`；這是現場位置，不是唯一安裝路徑。

![原環境的 Selenium 模組目錄](../../examples/custom-app-login/requirements/模組.png)

若使用 ZIP，解開後確認只有一層 selenium 根目錄且內含 Selenium.psd1、Selenium.psm1 與 assemblies，不可再套一層 selenium。依選定的 Chrome 版本準備相容 ChromeDriver，先備份再替換實際載入模組的 assemblies 內檔案，留下前後版本及雜湊。

![原環境的 assemblies 與 ChromeDriver 位置](../../examples/custom-app-login/requirements/更新driver.png)

使用與 RemoteApp 相同的執行帳戶，在 PowerShell 7 查驗模組是否可讀取。以下僅查詢已安裝模組資訊，不安裝或啟動瀏覽器：

```powershell
Get-Module -ListAvailable Selenium |
    Select-Object Name, Version, ModuleBase
$env:PSModulePath -split [IO.Path]::PathSeparator
```

原始網頁 PS1 只指定 `-Browser chrome`，沒有明確指定 Chrome Dev 執行檔；同機有 Stable／Dev 多版本時，要在受控測試核對實際啟動的執行檔與版本。不能因安裝了 Dev 就假設 Selenium 一定選到它。

## 放置 PS1 與設定發佈項目

原圖採 `C:\custom\<應用程式>\<應用程式>.ps1`。例如將原始 ApexOne.ps1 放到 `C:\custom\ApexOne\ApexOne.ps1`；由管理者控制目錄寫入權限，工作階段帳戶只取得必要讀取／執行權限。

截圖中的 ApexOne 設定如下；這是 Remote Application Publisher 的欄位內容，不是直接貼到 PowerShell 主控台執行的命令：

| 欄位 | 原圖內容 |
|---|---|
| Name／Full Name | ApexOne |
| Program Path | `||ApexOne` |
| Command Line | 見下方 |

```text
--cmd "C:\Program Files\PowerShell\7\pwsh.exe" --args "-File C:\custom\ApexOne\ApexOne.ps1 -username {username} -password {password} -asset {asset}"
```

原始 `pwsh.txt` 另採 `-asset {Target.AssetNetworkAddress}`，並帶有 `--enable-debug`。兩種 asset 替代欄位的適用設定不能只由截圖確認；依實際 SPP／Launcher 設定選擇，驗收時核對帶入值確為目標資產，不在正式記錄輸出密碼。本文範例省略 debug，避免未確認記錄遮罩前留下敏感資料。

大多數腳本自行加上 https://，因此 asset 預期為主機名稱、IP 或需要的 host:port，不含 scheme；Nessus 會自行加入 8834。`pve_auth1.ps1` 可接收 URL，未含 scheme 時補 https://，但不自動補 8006。各腳本不可一律套用同樣 asset 格式。

## 腳本對照

| 原始腳本 | 截圖中有發佈項目 | 原始實作與限制 |
|---|---|---|
| [ApexOne.ps1](../../examples/custom-app-login/scripts/ApexOne.ps1) | 有 | HTTPS，labelUsername／labelPassword |
| [ArubaVC.ps1](../../examples/custom-app-login/scripts/ArubaVC.ps1) | 有 | HTTPS，login-username／login-password |
| [Dell.ps1](../../examples/custom-app-login/scripts/Dell.ps1) | 有 | HTTPS，iDRAC 絕對 XPath，UI 改版需重測 |
| [DrIP.ps1](../../examples/custom-app-login/scripts/DrIP.ps1) | 有 | HTTP，USER_TB／PWD_TB |
| [Fortigate.ps1](../../examples/custom-app-login/scripts/Fortigate.ps1) | 有 | HTTPS，username／secretkey |
| [FortigateSW.ps1](../../examples/custom-app-login/scripts/FortigateSW.ps1) | 有 | HTTPS，username／password |
| [HPESW.ps1](../../examples/custom-app-login/scripts/HPESW.ps1) | 有 | HTTPS，inputUsername／inputPassword |
| [Nessus.ps1](../../examples/custom-app-login/scripts/Nessus.ps1) | 有 | HTTPS，自動加 :8834 |
| [NReporter.ps1](../../examples/custom-app-login/scripts/NReporter.ps1) | 有 | HTTPS，username／password |
| [PVE.ps1](../../examples/custom-app-login/scripts/PVE.ps1) | 有 | 動態元素 ID、password 指向 inputWrap，realm 選取器含 namr 疑點 |
| [Synology.ps1](../../examples/custom-app-login/scripts/Synology.ps1) | 有 | HTTP，分兩階段輸入帳號與密碼 |
| [Netapp.ps1](../../examples/custom-app-login/scripts/Netapp.ps1) | 無 | HTTPS，XPath 與 CSS Selector |
| [Paloalto.ps1](../../examples/custom-app-login/scripts/Paloalto.ps1) | 無 | HTTPS，user／passwd |
| [Peplink.ps1](../../examples/custom-app-login/scripts/Peplink.ps1) | 無 | HTTPS，Name 與 Class 選取 |
| [pve_auth1.ps1](../../examples/custom-app-login/scripts/pve_auth1.ps1) | 無 | PVE realm 可指定、使用 Timeout；成功資源樹檢查被註解 |
| [MSSQL.ps1](../../examples/custom-app-login/scripts/MSSQL.ps1) | 無 | SSMS 20.x 繁體中文 UI Automation；非 Selenium |

## 原始實作限制與驗收

原檔保留供追溯，本次未把它們改成新的正式部署腳本。需在隔離測試主機確認以下行為，再投入共用發佈環境：

- 網頁腳本普遍以 `taskkill /f /im chromedriver.exe` 結束程序，沒有鎖定本次 PID，可能終止其他使用者的 driver。應先完成工作階段隔離與程序生命週期設計，再驗收兩人同時登入。
- `ignore-certificate-errors` 會略過憑證驗證；DrIP／Synology 原檔使用 HTTP。正式環境應依設備能力配置可信任 HTTPS，不能把這些來源設定視為安全建議。
- 命令列有密碼參數，可能被有權讀取程序資訊者或記錄工具取得；含空白、引號與特殊字元的憑證也須測試傳遞結果，不保存真實密碼命令列。
- 多數腳本只有固定等待，按下登入後未驗證成功；Chrome／driver 相容仍可能因 XPath 或登入流程變更而失敗。
- MSSQL 的 `#requires -Version 5.1` 只是最低版本聲明，不代表已驗證 PowerShell 7 相容。它使用 UIAutomation／Win32 且依 SSMS 20.x 繁體介面；需另外測試執行環境。`-ResetProfile` 刪除 SqlStudio.bin、`-TrustServerCertificate` 略過伺服器憑證驗證，來源檔沒有 WhatIf 保護，不宜直接套用。

每個發佈項目應記錄 PowerShell、模組、瀏覽器實際路徑及版本、ChromeDriver 版本、目標應用程式版本、asset 格式與預期登入頁。使用專用測試帳戶確認正確主機與身分、失敗訊息、登出／歸還及 SPS 側錄對應，再測同時兩個工作階段是否互相影響。沒有測試記錄的項目維持「來源範例」，不標成驗收通過。

## 取得檔案與相關文件

大型套件採 Git LFS，取得專案後執行 `git lfs pull`。以 [manifest.json](../../examples/custom-app-login/manifest.json) 核對 SHA-256；本次保存的 23 個原始檔案與來源位元組一致。來源資料夾內其他設備表、授權檔與客戶文件不屬於代登 PS1／元件範圍，未納入。

- [KB 目錄](README.md)
- [原始腳本、元件與限制](../../examples/custom-app-login/README.md)
- [RemoteApp 整合 SOP](../sop/remoteapp-integration.md)
