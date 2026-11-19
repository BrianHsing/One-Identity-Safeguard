# 客製化應用程式代登範例

本目錄保存使用者提供的 PowerShell 代登腳本與 6 個 requirement 檔案。除了 `MSSQL.ps1`（已換成改良版）與新增的 `SPS.ps1` 兩支經實測的改良版之外，其餘來源檔案原樣納入，沒有改動登入邏輯，也不是經驗收的通用部署套件。

部署步驟見 [RemoteApp 整合 SOP](../../docs/sop/remoteapp-integration.md)；各腳本的 asset 格式、限制與排錯案例見 [KB-003：客製化應用程式代登腳本參考](../../docs/kb/custom-app-login-selenium.md)。

- `scripts/`：16 支 Selenium 網頁代登腳本（含改良版 `SPS.ps1`）及 1 支 MSSQL／SSMS UI 自動化腳本（改良版 `MSSQL.ps1`）。
- `requirements/`：PowerShell MSI、Selenium NUPKG／ZIP、兩張配置圖及原始呼叫文字。
- [manifest.json](manifest.json)：23 個原始檔案的大小及 SHA-256，包含發佈畫面，可核對來源與下載完整性。`MSSQL.ps1` 已換成改良版，與 manifest 不符；原始版本可由 `git show 1b986d8:examples/custom-app-login/scripts/MSSQL.ps1` 取得。

## 取得完整安裝元件

三個大型套件由 Git LFS 管理。複製儲存庫後，在儲存庫目錄執行 `git lfs pull`，並以 manifest 核對雜湊；只取得 LFS 指標文字時不可安裝。GitHub 的一般 ZIP 下載不保證包含實體 LFS 檔案。

PowerShell 7.4.6 與 Selenium 4.0.0-preview3 是來源環境留存版本，不是現行部署版本建議。Google Chrome Dev 安裝檔不在提供的 requirement 目錄內；不能視為完整離線安裝包。第三方元件各依原廠授權，專案不變更其授權條件。

## 現行瀏覽器與 driver 放置方式

依 [RemoteApp SOP 步驟 2](../../docs/sop/remoteapp-integration.md#步驟-2部署-powershell-7selenium-與-chrome-for-testing)，主要配置如下：

```text
C:\Automation\chrome\chrome.exe
C:\Program Files\PowerShell\7\Modules\selenium\assemblies\chromedriver.exe
```

Chrome 使用完整 Chrome for Testing 套件，ChromeDriver 採同一發布版本。若模組有版本子目錄，以實際載入命令所屬模組的 `ModuleBase\assemblies` 為準。部署副本透過 `-BinaryPath` 指定瀏覽器 EXE、`-WebDriverPath` 指定此 assemblies **資料夾**；driver 不必加入 PATH。保存套件的 Chrome 啟動函式也會讀取 `ChromeWebDriver` 環境變數，明確指定路徑可避免選到其他 driver。

更換 driver 前備份並記錄版本、來源及 SHA-256；模組更新、重裝或重新解壓縮可能覆蓋 driver 或改變 ModuleBase，完成後須重新核對並測試。來源 ZIP 附帶的 driver sha256 與實際檔案不一致，詳見 KB，不可直接採信。此規範用於部署副本；`scripts/`、套件及 manifest 保留來源位元組，不在本次文件修訂中更改。

## 執行前須處理的原始腳本限制

多數網頁腳本會以命令列接收密碼、略過 TLS 憑證錯誤，並在結尾執行 `taskkill /f /im chromedriver.exe`。這可能影響同主機其他代登工作，不能直接當成共用發佈主機的安全完成範本。不要用真實密碼測試命令列或啟用未確認遮罩行為的 debug／Transcript。

`PVE.ps1` 使用動態 ID 與疑似拼字錯誤 `[namr=realm]`，另有獨立的 `pve_auth1.ps1`；兩者均保留，不宣稱新版已完全驗收。`MSSQL.ps1` 採 Windows UI Automation，與 Selenium 分開；`-ResetProfile` 會刪除該帳戶 SSMS 19.x／20.x 的 `UserSettings.xml` 與 `SqlStudio.bin`。`SPS.ps1` 只結束自己啟動的 chromedriver。其他原始腳本不具一致的 WhatIf／稽核機制，正式部署前須另行完成修改與驗收。
