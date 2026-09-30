# Safeguard 知識庫（KB）

本區收錄既有操作文件與問題處理指引；SOP 放在 [操作程序目錄](../sop/environment-evidence.md)，KB 則依問題或使用情境查找。

| 編號 | 主題 | 版本與證據 |
|---|---|---|
| KB-001 | [SPP 外部 Federation 登入出現 AADSTS75011](spp-federation-aadsts75011.md) | 原文件為 SPP 9.0／API v4；官方 KB 引用 v3，本次原廠頁面 403 |
| KB-002 | [RDP 工作階段重新導向本機磁碟](safeguard-rdp-drive-redirection.md) | 原文件未載 SPP／SPS 版本；保留歷史操作圖 |
| KB-003 | [RemoteApp／PowerShell Selenium 客製化代登](custom-app-login-selenium.md) | 16 支來源 PS1、6 個 requirement 檔案與發佈截圖；未執行驗收 |

## 來源與保存

2026-09-30 由使用者提供兩份 Word 文件，原始檔逐位元複製至本機 `docs/kb/source-documents-local/`，不改動來源 Word。該資料夾由 `.gitignore` 排除，不會隨 clone 取得；[sources.json](sources.json) 記錄檔名、大小及 SHA-256，可核對本機原檔。

最初兩份 Word 的匯入批次包含兩篇可閱讀的 Markdown KB 與 13 張原文件圖片。磁碟文件第 4 張包含完整連線字串，未提交；其他圖片保留原樣，不以生成圖替代實際畫面。原始檔及舊圖仍包含環境識別資料，對外提供前須去識別。

本文是來源整理，沒有執行文件中的設備變更。已將現場案例、官方依據與尚未驗收事項分開說明。

[返回專案首頁](../../README.md)
