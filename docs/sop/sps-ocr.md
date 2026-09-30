# SPS OCR 設定與套用

## 目的

將圖形工作階段的畫面文字建立索引，供事後搜尋與定位側錄。

## 適用範圍

以下是 SPS 8.0 LTS 寫法。圖形協定的 OCR 與 SSH 文字索引不同，也不等同於即時內容阻擋。

## 前置條件

具有 Indexer Policies 與目標連線原則設定權限；側錄已正常產生。加密側錄須具備索引所需的解密金鑰並依內部規範保管。

## 操作步驟

1. 到 `Basic Settings > Local Services > Indexer service` 確認索引服務啟用，依 CPU、記憶體與現有佇列設定平行處理量，儲存。
2. 到 `Policies > Indexer Policies` 建立測試原則。要搜尋畫面內文時啟用 Screen content；lightweight_indexing 僅提供較精簡的命令／視窗標題索引，不足以取代完整畫面索引。
3. 已知語言時使用 Manual language selection。繁體中文情境選 Traditional Chinese，依官方建議避免再混選拉丁字母語言。
4. 選擇辨識精度。先以少量側錄比較速度與辨識率，再決定正式負載設定。
5. 到目標協定的 Connections 選取測試連線原則，在 Enable indexing 選擇新 Indexing Policy，儲存。
6. 建立新 RDP 工作階段，在畫面輸入無敏感資料的唯一識別字串，例如 `PAM-OCR-TEST-20260930`，結束後等待索引完成，再搜尋並核對畫面時間點。
7. 使用繁體中文測試文字重複驗證，記錄索引延遲與漏字情況；歷史側錄不因改原則就保證自動重新索引。

## 注意事項

OCR 受字型、畫面品質與語言影響，不保證逐字正確。完整畫面索引會增加負載；本專案建議保留原 Indexing Policy，若佇列持續增加，先將測試連線恢復原原則並調整容量。

## 相關文件

- [官方：SPS 8.0 LTS，內建索引與套用](https://support.oneidentity.com/de-de/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/administration-guide/82)
- [官方：OCR 語言限制](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/rest-api-reference-guide/47)
- [即時內容原則](sps-content-policy.md)
