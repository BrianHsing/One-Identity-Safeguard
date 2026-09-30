# 實機截圖與驗證範圍

## 目的

提供各 SOP 截圖的來源、版本與驗證界線，讓讀者能分辨現有設定、未儲存表單及實際測試結果。

## 適用範圍

2026-09-30 以使用者提供的管理環境檢視：SPP 9.0.0.2807、SPS 9.0.0。截圖來自實際瀏覽器，不是模擬圖。根目錄舊部署圖片沿用原環境，不等於這次 9.0 介面。

官方來源分開標示：各篇原理與部分部署步驟保留已查證的 8.0 LTS 官方文件。本次 SPS 9.0 介面提供的官方說明連結實際開啟為 404，未據此宣稱 9.0 文件已查證。UI 名稱、選項與既有狀態則以本次實機觀察為準；本文件不是版本相容性認證。

## 前置條件

使用經授權的管理帳戶，拍攝時避開密碼、Token、SAML metadata、通知信箱與個人帳戶清單。圖片保留必要的實驗室資產名稱與部分私有 IP，對外提供前仍須依客戶要求去識別。

## 操作步驟

### 按目的選擇 SOP

| 作業 | 已補實機證據 | 尚未驗收 |
|---|---|---|
| [登入](spp-admin-login.md)／[申請流程](spp-session-workflow.md) | 首頁、我的要求與核准入口 | 申請人到核准人的完整流程、RDP／SSH 登入與歸還 |
| [納管帳戶](spp-account-management.md) | 帳戶清單、一般與管理新增表單 | 新增帳戶與目標登入 |
| [服務帳戶](spp-service-account.md)／[輪替](spp-password-change.md) | 驗證欄位、設定／檢查／變更入口 | 實際連線、密碼變更與相依服務 |
| [密碼原則](spp-password-policy.md) | 規則摘要、共用提示與繼承 | 新規則套用及排程執行 |
| [權利](spp-entitlements.md) | 工作階段類型、需要核准與人數 | 範圍授權、緊急例外及負向測試 |
| [SPP 備份](spp-backup.md) | 既有自動備份完成清單 | 離機副本、解密與隔離還原 |
| [AD](spp-active-directory.md)／[Entra ID](spp-entra-id.md)／[Defender](defender-integration.md) | SPP 新增提供者空白表單 | 外部系統設定與登入往返 |
| [OCR](sps-ocr.md) | full_indexing、語言、RDP 指派、Indexer Status | 新側錄的中文與英文搜尋命中率 |
| [SPS 備份封存](sps-backup-archive.md) | 系統備份、封存門檻與連線指派 | 目的地檔案、封存、回放與還原 |
| [清理](sps-audit-cleanup.md) | 原則清單及保留分布 | 任何刪除作業 |
| [內容原則](sps-content-policy.md) | 事件、動作與 Drawing 通道 | 實際通知、中止與負向測試 |
| [RemoteApp](remoteapp-integration.md) | SPP 類型入口、SPS 通道現況 | RDS／Launcher 安裝、授權與程式啟動 |
| [SCALUS](scalus-install.md)／[Desktop Player](desktop-player-install.md) | 尚無本機安裝截圖 | 安裝、協定關聯與播放 |

### 現況與建議值不可混用

| 實機觀察 | 文件中的處理方式 |
|---|---|
| EX2016 驗證類型是「無」；帳戶密碼頁有警告 | 未認定自動密碼管理可用，先完成連線與檢查 |
| 共用密碼規則為 6–10 字元、不允許符號 | 僅作畫面示例，正式強度須依需求及平台限制設計 |
| Demo RDP 需要 1 人核准，但允許緊急存取 | 一般簽核與緊急例外分開驗收 |
| SPS System backup policy 空白，組態未選加密 | 尚未建立可驗收的系統備份保護流程 |
| safeguard_rdp 的 Backup／Archive policy 空白 | 有原則不等於已指派；先完成保存再啟用清理流程 |
| full_indexing 同選繁體中文與英文 | 按產品內建語言建議用專用原則比較辨識率 |
| MSTSC 比對字串含中文，Drawing 未指派 Content policy | 不宣稱中文即時阻擋有效或此原則已套用 |
| Indexer Status 為 0 failed／lost／waiting | 只證明檢視當下佇列與服務狀態，不能代替 OCR 測試 |

### 驗收紀錄

每次正式測試記錄日期、產品版本、操作者、原則名稱、資產／帳戶、申請或工作編號、預期結果、實際結果與證據位置。失敗須保留原訊息，不能以「有設定」、「有檔案」或「畫面有勾號」代替成功結果。

## 注意事項

本次僅檢視、搜尋、展開既有設定與開啟未儲存表單。資產驗證類型示範已取消；沒有建立帳戶或提供者、沒有儲存原則或 Commit、沒有變更密碼、沒有執行備份還原、封存、清理或中止連線。

圖片中警告、空白值與既有勾選刻意保留，並在相鄰文字說明，避免把不完整的現況包裝成完成範例。EX2016 是既有資產標籤，不是部署版本建議。

## 相關文件

- [專案操作目錄](../../README.md)
- [SPP 8.0 LTS 官方管理指南](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0-lts/administration-guide)
- [SPS 8.0 LTS 官方管理指南](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0-lts/administration-guide)
