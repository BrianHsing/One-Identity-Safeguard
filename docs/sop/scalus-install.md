# Windows 安裝與設定 SCALUS

## 目的

讓 SPP 網頁透過 URI 啟動本機 RDP／SSH 用戶端。SCALUS 是協定處理程式的分派工具，不提供目標存取授權。

## 適用範圍

Windows 操作方式依 OneIdentity/SCALUS 官方儲存庫 README；搭配本專案 SPP 8.0 LTS 工作階段。SCALUS 是獨立工具，其版本不等於 SPP 版本。

## 前置條件

具備軟體安裝權限、企業核准的 RDP／SSH 用戶端及一筆可用測試申請。安裝套件從官方 Releases 取得，記錄實際版本，確認來源及檔案完整性。

## 操作步驟

> 截圖範圍：本次連入 SPP／SPS 管理介面，沒有在用戶端執行本工具安裝或播放驗收。以下安裝程序保留原官方版本基準，不以管理網頁截圖冒充安裝精靈。實機已核對項目見[截圖與驗證範圍](environment-evidence.md)。

1. 從官方 Releases 下載 Windows MSI，完成安裝。官方 README 說明預設位於 `C:\Program Files\SCALUS` 並建立開始功能表捷徑。
2. 由開始功能表開啟 SCALUS。工具會在瀏覽器啟動本機設定介面。
3. 檢查 RDP／SSH 對應的應用程式路徑確實存在。使用工具提供的設定與範例調整，不把實際密碼寫進命令列或設定檔。
4. 到 SPP 使用者偏好確認啟用相應的啟動選項；開啟已核准且仍可用的測試申請。
5. 按下啟動工作階段，瀏覽器詢問外部應用程式時，確認由可信任的 SPP 網址發起並核對程式後再允許。
6. 確認用戶端連到 SPS 並到達正確目標，完成登出及歸還。分別測試 SSH 與 RDP，不能只看 SCALUS 設定頁可開啟就判定成功。

## 注意事項

SCALUS 官方將工具描述為一般用途 URI dispatcher；支援責任與企業核准版本應獨立確認。本專案建議避免對所有網站永久允許啟動外部程式。

若協定關聯衝突，先記錄原有關聯再調整。RDP 可依 SPP 官方流程改用下載的啟動檔，不需為測試而停用瀏覽器安全機制。

## 相關文件

- [官方：SCALUS README](https://github.com/OneIdentity/SCALUS)
- [官方：SCALUS Releases](https://github.com/OneIdentity/SCALUS/releases)
- [使用者工作階段流程](spp-session-workflow.md)
