# 客製化應用程式代登範例

RemoteApp 代登用的 PowerShell 腳本與安裝元件。

> [!NOTE]
> - **部署步驟**：[RemoteApp 整合 SOP](../../docs/sop/remoteapp-integration.md)
> - **各腳本的 asset 格式、限制與排錯案例**：[KB-003：客製化應用程式代登腳本參考](../../docs/kb/custom-app-login-selenium.md)

## 目錄內容

```text
custom-app-login/
├─ scripts/        17 支代登腳本（16 支 Selenium 網頁、1 支 SSMS UI Automation）
├─ requirements/   PowerShell 安裝檔、Selenium 模組、配置圖與原始呼叫文字
└─ manifest.json   23 個原始檔案的大小與 SHA-256
```

## 建議使用的腳本

| 腳本 | 目標 | 狀態 |
|---|---|---|
| [MSSQL.ps1](scripts/MSSQL.ps1) | SSMS 20（UI Automation） | **改良版，2026-11-19 實測成功** |
| [SPS.ps1](scripts/SPS.ps1) | SPS 管理網頁（Selenium） | **改良版，2026-11-19 實測成功** |
| 其他 15 支 | 各設備管理網頁（Selenium） | 原樣保存的來源範例，未經驗收 |

兩支改良版都會寫階段日誌（不記錄密碼），命令列寫法見 [SOP 步驟 4](../../docs/sop/remoteapp-integration.md#步驟-4在-publisher-建立發佈項目)。

> [!WARNING]
> **使用原始腳本前須先處理以下問題**，不能直接用在多人共用的發佈主機：
> - 結尾的 `taskkill /f /im chromedriver.exe` 會結束主機上**所有人**的 chromedriver。
> - 略過 TLS 憑證錯誤；`DrIP.ps1`、`Synology.ps1` 使用 HTTP。
> - 沒有指定 Chrome 與 driver 路徑，只用固定秒數等待頁面，也不確認登入結果。
> - `PVE.ps1` 使用動態 ID，realm 選取器含疑似拼字錯誤 `[namr=realm]`；另有 `pve_auth1.ps1` 可參考。
>
> 可參考 `SPS.ps1` 的做法修改。測試時不要使用真實密碼，也不要開啟可能收錄密碼的 debug 或 Transcript。

## requirements 內容

| 檔案 | 說明 |
|---|---|
| `PowerShell-7.4.6-win-x64.msi` | 來源環境的 PowerShell 安裝檔（Git LFS） |
| `selenium.4.0.0-preview3.nupkg` | PowerShell Gallery 的 Selenium 預覽版模組（Git LFS） |
| `selenium.zip` | 已整理的模組資料夾，內含的 ChromeDriver 與 NUPKG 不同（Git LFS） |
| `模組.png`、`更新driver.png` | 原環境的模組與 driver 放置位置 |
| `pwsh.txt` | 原始的 Launcher 呼叫文字 |

> [!IMPORTANT]
> 這些是**來源環境的留存版本**，不是現行部署建議；正式部署依支援與安全要求選版。目錄內**沒有** Chrome 安裝檔，現行標準是另從 Google 官方取得 Chrome for Testing，所以這裡不是完整的離線安裝包。

## 取得大型檔案

三個大型套件由 Git LFS 管理。GitHub 網頁的「Download ZIP」不保證包含實體檔案，請用 Git 取得：

```powershell
git clone https://github.com/BrianHsing/One-Identity-Safeguard.git
cd One-Identity-Safeguard
git lfs pull
```

取得後以 [manifest.json](manifest.json) 核對 SHA-256。只拿到 LFS 指標文字（檔案只有幾百位元組）時不能安裝。

## 部署位置

詳細步驟見 [SOP 步驟 2](../../docs/sop/remoteapp-integration.md#步驟-2部署-powershell-7selenium-與-chrome-for-testing)，標準位置如下：

```text
C:\Automation\chrome\chrome.exe                                              Chrome for Testing
C:\Program Files\PowerShell\7\Modules\selenium\assemblies\chromedriver.exe   同版本 ChromeDriver
C:\custom\<應用程式>\<應用程式>.ps1                                            代登腳本
```

- Chrome 與 ChromeDriver 必須是同一個發布版本；driver 不必加入 PATH，腳本以 `-BinaryPath`、`-WebDriverPath` 明確指定。
- 更換 driver 前先備份，記錄版本、來源與 SHA-256。`selenium.zip` 附帶的 `.sha256` 與實際 driver 不符，不能拿來驗收（原因見 KB-003）。

## 檔案完整性

`manifest.json` 記錄的是**原始來源檔案**的雜湊：

- `MSSQL.ps1` 已換成改良版，雜湊會與 manifest 不符。原始版本可這樣取得：

  ```powershell
  git show 1b986d8:examples/custom-app-login/scripts/MSSQL.ps1
  ```

- `SPS.ps1` 是之後新增的，不在 manifest 中。
- 其他腳本、套件與圖片保留來源位元組，應與 manifest 一致。

第三方元件各依原廠授權，本專案不變更其授權條件。
