# KB-003：客製化應用程式代登腳本參考

本篇是 RemoteApp 代登的**參考資料**：保存的套件與版本、各腳本的 asset 格式與限制、改良版腳本的做法，以及過去的排錯案例。

> [!NOTE]
> 部署與設定步驟請照 [RemoteApp 整合 SOP](../sop/remoteapp-integration.md) 操作，本篇不重複步驟。

## 快速查找

| 想知道 | 看哪裡 |
|---|---|
| 某支腳本的 `-asset` 要填什麼格式 | [腳本清單](#腳本清單) |
| 原始腳本有哪些風險、改良版怎麼處理 | [原始腳本的限制與改良版做法](#原始腳本的限制與改良版做法) |
| 遇到的錯誤以前有沒有發生過 | [案例紀錄](#案例紀錄) |
| 保存的套件版本、driver 雜湊為何對不上 | [保存的套件與版本](#保存的套件與版本) |
| 怎麼部署 Chrome for Testing 與 ChromeDriver | [SOP 步驟 2](../sop/remoteapp-integration.md#步驟-2部署-powershell-7selenium-與-chrome-for-testing) |
| Publisher 命令列怎麼寫 | [SOP 步驟 4](../sop/remoteapp-integration.md#步驟-4在-publisher-建立發佈項目) |

## 腳本清單

腳本放在 [代登範例目錄](../../examples/custom-app-login/README.md)。「Publisher 畫面」指 [SOP 圖 6](../sop/remoteapp-integration.md#42-建立發佈項目) 的發佈清單中是否有該項目。

> [!TIP]
> 大多數網頁腳本會自行補 `https://`，所以 `-asset` 填主機名稱、IP 或 `host:port`，**不要加 scheme**。例外見下表的「asset 格式」欄。

| 腳本 | 類型 | Publisher 畫面 | asset 格式 | 定位方式與備註 |
|---|---|---|---|---|
| [MSSQL.ps1](../../examples/custom-app-login/scripts/MSSQL.ps1) | SSMS 20（UI Automation） | 無 | `host`、`host,port` 或 `host\instance` | **改良版，已實測**。SSMS 20.x 繁體中文介面；固定使用 SQL Server 驗證 |
| [SPS.ps1](../../examples/custom-app-login/scripts/SPS.ps1) | 網頁（Selenium） | — | 主機或 `host:port`；已含 scheme 時不重複補 | **改良版，已實測**。`local-username`／`local-password`、class `flat primary` |
| [PGADMIN.ps1](../../examples/custom-app-login/scripts/PGADMIN.ps1) | pgAdmin 4 桌面版（UI Automation） | — | 主機或 `host:port`（預設埠 5432） | **改良版，已實測**。pgAdmin 9.19 英文介面；`-username` 是 PostgreSQL 帳戶 |
| [ApexOne.ps1](../../examples/custom-app-login/scripts/ApexOne.ps1) | 網頁 HTTPS | 有 | 主機 | `labelUsername`／`labelPassword` |
| [ArubaVC.ps1](../../examples/custom-app-login/scripts/ArubaVC.ps1) | 網頁 HTTPS | 有 | 主機 | `login-username`／`login-password` |
| [Dell.ps1](../../examples/custom-app-login/scripts/Dell.ps1) | 網頁 HTTPS | 有 | 主機 | iDRAC 絕對 XPath，介面改版需重測 |
| [DrIP.ps1](../../examples/custom-app-login/scripts/DrIP.ps1) | 網頁 **HTTP** | 有 | 主機 | `USER_TB`／`PWD_TB` |
| [Fortigate.ps1](../../examples/custom-app-login/scripts/Fortigate.ps1) | 網頁 HTTPS | 有 | 主機 | `username`／`secretkey` |
| [FortigateSW.ps1](../../examples/custom-app-login/scripts/FortigateSW.ps1) | 網頁 HTTPS | 有 | 主機 | `username`／`password` |
| [HPESW.ps1](../../examples/custom-app-login/scripts/HPESW.ps1) | 網頁 HTTPS | 有 | 主機 | `inputUsername`／`inputPassword` |
| [Nessus.ps1](../../examples/custom-app-login/scripts/Nessus.ps1) | 網頁 HTTPS | 有 | 主機（**不要**加埠） | 腳本自動加 `:8834` |
| [NReporter.ps1](../../examples/custom-app-login/scripts/NReporter.ps1) | 網頁 HTTPS | 有 | 主機 | `username`／`password` |
| [PVE.ps1](../../examples/custom-app-login/scripts/PVE.ps1) | 網頁 HTTPS | 有 | 主機 | 動態元素 ID；password 指向 inputWrap；realm 選取器含疑似拼字錯誤 `namr` |
| [Synology.ps1](../../examples/custom-app-login/scripts/Synology.ps1) | 網頁 **HTTP** | 有 | 主機 | 分兩階段輸入帳號與密碼 |
| [Netapp.ps1](../../examples/custom-app-login/scripts/Netapp.ps1) | 網頁 HTTPS | 無 | 主機 | XPath 與 CSS Selector |
| [Paloalto.ps1](../../examples/custom-app-login/scripts/Paloalto.ps1) | 網頁 HTTPS | 無 | 主機 | `user`／`passwd` |
| [Peplink.ps1](../../examples/custom-app-login/scripts/Peplink.ps1) | 網頁 HTTPS | 無 | 主機 | Name 與 Class 選取 |
| [pve_auth1.ps1](../../examples/custom-app-login/scripts/pve_auth1.ps1) | 網頁 HTTPS | 無 | 主機或完整 URL | 未含 scheme 時補 `https://`，但**不會**補 `:8006`；可指定 realm、使用 Timeout；成功檢查被註解 |

除了標示「改良版，已實測」的三支，其餘都是原樣保存的來源腳本，沒有測試紀錄，維持「來源範例」狀態。

## 原始腳本的限制與改良版做法

| 限制 | 影響 | 改良版的做法 |
|---|---|---|
| 結尾執行 `taskkill /f /im chromedriver.exe` | 結束主機上**所有人**的 chromedriver | SPS.ps1 只結束父程序為自己的 chromedriver |
| 未指定 Chrome 與 driver 路徑，只寫 `-Browser chrome` | 可能用到其他版本的 Chrome 或 driver | SPS.ps1 以 `-BinaryPath`、`-WebDriverPath` 明確指定，找不到時記錄警告 |
| 固定 `Start-Sleep` 等待 | 頁面較慢時找不到欄位 | SPS.ps1 每 0.5 秒檢查一次，最多等 `-TimeoutSec` 秒 |
| 按下登入後不確認結果 | 失敗時無從得知 | SPS.ps1 確認是否離開登入頁；MSSQL.ps1 判斷連線成功或錯誤並記錄錯誤內容 |
| 沒有日誌 | RemoteApp 沒有主控台，失敗時無法判斷停在哪一步 | 三支都寫階段日誌，不記錄密碼 |
| `ignore-certificate-errors` 略過憑證；DrIP、Synology 使用 HTTP | 失去中間人防護 | SPS.ps1 預設仍略過，可用 `-VerifyCertificate` 恢復；正式環境應配置可信任的 HTTPS |
| 密碼經命令列傳入 | 有權讀取程序資訊的人可能看到；特殊字元可能被拆錯 | Launcher 的設計限制，無法由腳本解決；以測試密碼驗證特殊字元 |
| 沒有 `#requires -Version 7.0` | 誤用 Windows PowerShell 5.1 時 Selenium 可能載入失敗 | SPS.ps1 加上 `#requires -Version 7.0` |

MSSQL.ps1 的其他設計重點：

- 先把驗證方式切到「SQL Server 驗證」，並等登入欄位真的啟用後才填值。
- 「信任伺服器憑證」先嘗試以 UI Automation 讀取狀態；在 SSMS 20.2.37.0 讀不到，所以退回切換。因此 `-TrustServerCertificate` 必須搭配 `-ResetProfile`（見 [SOP 範例一](../sop/remoteapp-integration.md#範例一mssqlssms-20桌面程式)）。
- 只有錯誤內容判定為憑證錯誤時，才改用第二種切換方式重試一次。
- `-ResetProfile` 刪除的是 SSMS 19.x／20.x 的 `UserSettings.xml` 與 `SqlStudio.bin`，也會清掉該帳戶的伺服器連線紀錄與偏好設定。

PGADMIN.ps1 的設計重點（pgAdmin 9.19 實測得出）：

- 伺服器以 `setup.py load-servers --replace` 登錄，不寫密碼；呼叫前要把 `runtime` 資料夾（含 `libpq.dll`）加入 PATH，並以 UTF-8 解碼輸出。啟動 pgAdmin 前會清掉這些暫時的環境變數。
- pgAdmin 的頂層視窗從 UI Automation 根節點列舉不到，改以 Win32 `EnumWindows` 找到後再轉成 UIA 元素。
- 物件樹節點只露出 Text 元素，沒有 TreeItem 與展開模式；收合中的節點沒有座標，右方向鍵也無效，所以雙擊「Servers」展開，pgAdmin 會自動對唯一的伺服器跳出連線對話框。
- 密碼以 `SendInput`（`KEYEVENTF_UNICODE`）逐字送出，日誌記錄送出的事件數（應為長度 × 2）；不用剪貼簿，避免經 RemoteApp 同步到使用者端。
- OK 按鈕名稱前有圖示字元（實際為「 OK」），以正規比對尋找。
- 連線對話框關閉即判定成功；失敗時記錄錯誤並把對話框留給使用者。
- pgAdmin 先顯示載入視窗、再換成主視窗，且會套用上次的視窗大小；最大化前重新找主視窗，不生效時改調成螢幕工作區大小。

## 案例紀錄

### 2026-11-19：MSSQL（SSMS）RemoteApp 代登

環境：SSMS 20.2.37.0、PowerShell 7.4.6，RemoteApp 執行帳戶 `sg_svc`，目標 SQL Server 10.16.10.103。最終以 SQL 驗證（`sa`）代登成功。

| 現象 | 原因 | 處理 |
|---|---|---|
| RemoteApp 錯誤：「無法打開此程式或檔案。若不是 \|\|SSMS 有問題…」 | SPP 原則的別名 `\|\|SSMS` 與 Publisher 的項目名稱 `MSSQL` 不一致 | 原則改為 `\|\|MSSQL` |
| 修正別名後仍出現同樣錯誤 | Launcher 命令列約 300 字元。縮短到約 165 字元即恢復；之後 203 字元也成功。未逐一還原參數，無法確定是長度上限或特定參數 | 只傳必要參數 |
| SSMS 出現 `error: 40 - Could not open a connection to SQL Server` | 網路層連不到 SQL Server（15:35–15:58）。16:00 起恢復，期間的伺服器端變更未記錄 | 屬伺服器或網路設定，非腳本問題 |
| 腳本把網路錯誤誤判為憑證錯誤並重試 | 錯誤方塊與登入對話框同名，且掛在登入對話框底下；舊版抓到外層對話框，讀到「憑證中的主機名稱」標籤 | 已修正（commit `64852c9`）：排除含「連線(C)」按鈕的登入對話框 |
| 不加 `-TrustServerCertificate` 也能登入 | SSMS 記住了先前執行時的勾選。加上 `-ResetProfile` 回到未勾選後，出現 `SSL Provider` 的「此憑證鏈結是由不受信任的授權單位發出的」 | 正式命令列使用 `-TrustServerCertificate -ResetProfile` |
| 日誌顯示「信任伺服器憑證初始狀態：無法讀取」 | SSMS 20.2.37.0 的勾選框不支援 UI Automation 的 TogglePattern | 腳本退回切換，需搭配 `-ResetProfile` |
| 目標帳戶 `Administrator@yjcloud.org` 無法登入 | 疑似 AD 網域帳戶；SQL Server 驗證只接受 SQL 登入（該次同時有網路錯誤，未單獨確認） | 改用 SQL 登入 `sa` |

同一發佈主機的觀察：未安裝 RD 工作階段主機角色（`RDS-RD-Server` 為 Available）、Windows 尚未啟用（事件 8198，slui `0x87E10BC6`），RemoteApp 仍可啟動：以 Remote Application Publisher 發佈時不需要 RDSH，但最多 2 個同時工作階段；Windows 啟用則一律需要。RDS CAL 是否需要須另向授權窗口確認（見 [SOP 前置條件](../sop/remoteapp-integration.md#前置條件)）。

### 2026-11-19：pgAdmin（PostgreSQL）RemoteApp 代登

環境：pgAdmin 4 9.19 桌面版、PowerShell 7.4.6，RemoteApp 執行帳戶 `sg_svc`，目標 PostgreSQL 18（10.16.10.103，`postgres` 帳戶，未啟用 SSL）。最終代登成功，從啟動到連線約 15 秒。

| 現象 | 原因 | 處理 |
|---|---|---|
| SPP Check System：`SSL connection requested. No SSL enabled connection from this host is configured.` | 資產勾了 Use SSL，PostgreSQL 未提供 SSL | 取消勾選 Use SSL（長期應在 PostgreSQL 啟用 SSL） |
| SPP Check System：`PostgresException 28000` 加亂碼 | PostgreSQL 以 Big5 回傳「no pg_hba.conf entry」，SPP 來源 IP 10.16.10.110 未被放行 | `pg_hba.conf` 加入 SPP 與發佈主機 10.16.10.108 的規則並 reload |
| `setup.py` 失敗：`no pq wrapper available` | 直接呼叫 pgAdmin 的 Python 時，PATH 沒有 `libpq.dll` 所在的 `runtime` 資料夾 | 腳本呼叫前把該資料夾加入 PATH |
| `Got unexpected extra argument(s) (- - r e p l a c e)` | PowerShell 的 `if` 運算式把單一元素陣列攤平成字串，展開時被拆成逐字元參數 | 宣告為 `[string[]]` |
| 日誌中 setup.py 的輸出變成問號 | Python 以 UTF-8 輸出，PowerShell 以 CP950 解碼 | 呼叫期間把 `[Console]::OutputEncoding` 改為 UTF-8 |
| RemoteApp 只看到黑色視窗，日誌顯示 120 秒內找不到 pgAdmin 視窗 | 黑色視窗是 Launcher 主控台；pgAdmin 實際已啟動，但從 UIA 根節點列舉不到它的視窗 | 改以 Win32 `EnumWindows` 找視窗 |
| 找到伺服器文字卻沒有可點擊的位置 | 伺服器收合在 Servers 底下，物件樹節點不在 UIA 樹中 | 雙擊 Servers 展開 |
| 連線失敗：密碼驗證失敗（Big5 亂碼） | 舊版以 `SendKeys` 輸入，按鍵受 CapsLock 或輸入法影響 | 改用 `SendInput` Unicode 輸入 |
| 找不到 OK 按鈕，改送 Enter | 按鈕名稱為「 OK」，前面有圖示字元 | 改用正規比對 |
| 視窗偏小，最大化未生效 | 第一次最大化作用在載入視窗；之後 pgAdmin 套用上次的視窗大小 | 最大化前重新找主視窗，不生效時調成螢幕工作區大小 |

### 2026-11-19：SPS 改良版腳本

以改良版 SPS.ps1 登入 SPS 管理網頁成功：Chrome for Testing 與 ChromeDriver 同為 155.0.8059.79，driver 啟動後 1 秒內出現登入欄位，按下登入 1 秒內離開登入頁，只結束了本次啟動的 chromedriver。該次執行帳號為 `Administrator`。

### 2026-10-07：`cannot find Chrome binary`

`<CUSTOMER_TEST_USER>` 互動測試成功，但 RemoteApp 以 `<CUSTOMER_REMOTEAPP_USER>` 執行，讀不到前者的 User PATH，約 3 秒後在建立 WebDriver 工作階段時出現 `cannot find Chrome binary (SessionNotCreated)`。改用 Machine PATH 並重建工作階段後，使用者回報成功。現行做法改以 `-BinaryPath` 明確指定 Chrome。

**教訓：測試與驗收都要用 RemoteApp 實際執行帳戶。**

### PowerShell 5.1 載入 WebDriver.dll 失敗

同一套 Selenium 模組在 Windows PowerShell 5.1 載入 WebDriver.dll 失敗，在 PowerShell 7 成功（日誌記錄 PowerShell 7.4.17，Selenium 顯示 4.0.0）。這是本案觀察，不代表所有 Selenium 套件都不支援 5.1。`#requires -Version 7.0` 只限制最低版本，不會自動改用 PowerShell 7，Launcher 必須明確呼叫 `pwsh.exe`（[Requires 說明](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-7.4)）。

### StartURL：`Only String attributes are supported`

單獨貼上 `Start-SeDriver` 測試時，`$asset` 沒有在同一工作階段指定，傳入空值造成轉換失敗。補上完整 URL 後正常。

### Chrome Dev 的版本漂移（歷史背景）

原案例使用 Chrome Dev。Chrome Dev 與一般 Chrome 會自動更新，自動化環境的版本因此改變；把測試檔案放進既有 Chrome 安裝目錄，也會讓安裝與更新互相干擾。曾遇到更新或覆蓋問題，但沒有完整的更新程序證據。現行標準改用不會自動更新的 Chrome for Testing。

## 保存的套件與版本

| 元件 | 保存內容 | 說明 |
|---|---|---|
| PowerShell | `PowerShell-7.4.6-win-x64.msi` | 來源環境的安裝檔，不是要求新環境固定使用此版本 |
| Selenium 模組 | `selenium.4.0.0-preview3.nupkg` | nuspec 為 4.0.0-preview3；psd1 的 ModuleVersion 為 4.0.0、Prerelease 為 preview3 |
| 已整理的模組資料夾 | `selenium.zip` | 含 selenium 根目錄與 assemblies；內含的 ChromeDriver 與 NUPKG 不同 |
| Chrome Dev | 無安裝檔 | 只有使用者說明，沒有完整版本證據 |
| 配置參考 | `模組.png`、`更新driver.png`、`pwsh.txt` | 保留原始資料；`pwsh.txt` 的 `--enable-debug` 不作預設建議 |

「Selenium 4.0」指 PowerShell Gallery 的 [Selenium 4.0.0-preview3 模組](https://www.powershellgallery.com/packages/Selenium/4.0.0-preview3)（預覽版），不是 Selenium .NET／Java SDK 的相容性聲明。`Get-Module` 只顯示 4.0.0，無法分辨 preview 標籤，部署時須保存套件來源與雜湊。

### ZIP 內的 driver 雜湊對不上

直接計算壓縮檔內 `chromedriver.exe` 的位元組（未執行該檔案）：

| 套件 | chromedriver.exe SHA-256 |
|---|---|
| NUPKG | `c6131a3106a8956702459673bdcc7f37bdd8989a141d2cbe15dc0157f0d53c74` |
| ZIP | `ba21fb58c0be6963b7dba8efdfa8b772b014b2fa3c455f6328101f2ae883859a` |

ZIP 附帶的 `chromedriver.exe.sha256` 仍是 NUPKG 的雜湊，與 ZIP 內實際的 driver 不符。這符合「曾手動更換 driver」的情況，但不能當作來源可信的證明。部署前另行核對原廠來源、實際版本與雜湊，不要採信舊的 `.sha256` 附檔。兩個套件都原樣保存。

## 每個發佈項目應保存的紀錄

- PowerShell、Selenium 模組、瀏覽器的實際路徑與版本，ChromeDriver 版本與 SHA-256。
- 目標系統版本、asset 格式、預期的登入頁。
- 以專用測試帳戶確認：正確主機與身分、失敗訊息、登出與歸還、SPS 側錄對應，以及兩個工作階段同時使用是否互相影響。

沒有測試紀錄的項目維持「來源範例」，不標成驗收通過。

## 取得檔案

大型套件以 Git LFS 管理，取得專案後執行 `git lfs pull`，再以 [manifest.json](../../examples/custom-app-login/manifest.json) 核對 SHA-256。manifest 記錄的是原始來源檔案；MSSQL.ps1 已換成改良版，原始版本可由 `git show 1b986d8:examples/custom-app-login/scripts/MSSQL.ps1` 取得。來源資料夾內的設備表、授權檔與客戶文件不屬於代登範圍，未納入。

- [KB 目錄](README.md)
- [代登範例目錄](../../examples/custom-app-login/README.md)
- [RemoteApp 整合 SOP](../sop/remoteapp-integration.md)
