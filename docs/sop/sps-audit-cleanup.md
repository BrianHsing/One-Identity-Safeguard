# SPS 稽核資料清理原則

## 目的

依核准的保存期限清除過期稽核資料，避免刪除尚須保存的證據。

## 適用範圍

以下是 SPS 8.0 LTS 的 Audit Data Cleanup Policies 寫法，會影響 zat 與 metadata，屬不可依賴直接復原的刪除作業。

## 前置條件

資料擁有人已核准保存期限與排除範圍，完成[備份與封存回放驗證](sps-backup-archive.md)。涉及調查、訴訟或法遵保全的側錄須排除在清理範圍外。

## 操作步驟

1. 記錄原則名稱、適用連線原則、保存天數與應排除的工作階段。先用搜尋確認查詢的實際命中範圍並抽樣回放。
2. 到 `Policies > Audit Data Cleanup Policies` 選擇 `Add policy`。
3. 在 Policy name 輸入唯一名稱；Audit data older than 填核准的天數。本版官方允許 30–100,000 天，不為了測試而縮短正式保存期限。
4. Audit data query 限縮到已驗證的對象。若測試連線原則確實命名為 `ssh-pilot`，可使用 `protocol:SSH AND recording.connection_policy:ssh-pilot`；環境名稱不同時須重新查詢驗證，不能直接套用。
5. 再次核對天數與查詢後儲存。官方說明每日 22:01 執行資料庫清理，規劃時需確認裝置時間設定及封存完成時間。
6. 清理後核對到期測試資料與未到期資料，確認刪除範圍符合預期，留存查詢、筆數與執行紀錄。

## 注意事項

本專案建議以清理期限大於封存期限並保留緩衝的方式安排，不只把兩項作業排在同一天。封存檔存在也不代表原搜尋索引、metadata 與回放鏈仍完整。

若發現條件錯誤，立即停用或移除新建清理原則以停止後續刪除；已刪資料須評估備份復原，不承諾可由介面取消復原。

## 相關文件

- [官方：SPS 8.0 LTS，Configuring cleanup policies](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/administration-guide/28)
- [回專案目錄](../../README.md)
