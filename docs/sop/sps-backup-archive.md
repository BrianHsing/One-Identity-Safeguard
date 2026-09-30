# SPS 備份與封存原則

## 目的

分別保存系統組態、連線資料及側錄，並在可回放的前提下釋放裝置空間。

## 適用範圍

以下是 SPS 8.0 LTS 寫法。Backup 建立復原副本；Archive 將符合條件的資料移至外部儲存後移除本機資料，不能把兩者當成相同作業。

## 前置條件

已核准保存期限，準備可用的 SMB／NFS／Rsync over SSH 目的地及權限。每個用途與節點使用專用目錄，先建立共用與所需子目錄。備份目標不可混放其他檔案，官方警告備份可能刪除目標目錄內其他資料。

## 操作步驟

1. 在 `Policies > Backup & Archive > Backup policies` 建立系統備份原則，設定目的地、驗證與排程。
2. 到 `Basic Settings > Management > System backup` 指派該原則並啟用 Encrypt configuration，依官方程序使用 GPG 保護組態；私密金鑰離機保存。
3. 另外建立連線資料備份原則，在各協定 `Connections` 的 Backup policy 指派並儲存。系統備份不包含 audit trail，不能省略此步。
4. 執行測試備份，確認目標檔案及工作結果。隔離演練需先還原相符的系統組態與 metadata，再還原連線資料。
5. 在 Archive policies 建立封存原則，選定移至遠端伺服器的方式、目的地、排程與本機保存天數；本例不使用直接刪除資料的選項。
6. 將封存原則套至單一測試連線原則。叢集使用節點區隔目錄，保留適當的 Cluster Node ID 路徑設定。
7. 待一筆到期的測試側錄完成封存後，從搜尋結果回放，驗證遠端存取及解密均成功，再擴大套用。

## 注意事項

組態加密不代表整份備份中所有資料均加密，儲存端仍須限制存取。曾用於封存資料的 Archive Policy 不可任意刪除，以免失去對既有側錄的存取關係。

本專案建議讓清理期限長於封存門檻並保留失敗補跑緩衝。若封存或回放失敗，停止擴大套用並暫停相關清理，保留來源及原則供排查。

## 相關文件

- [官方：SPS 8.0 LTS，系統備份](https://support.oneidentity.com/it-it/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/administration-guide/8)
- [官方：資料與組態備份及目標目錄警告](https://support.oneidentity.com/ja-jp/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/administration-guide/25)
- [官方：封存、資料備份與加密](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/administration-guide/basic-settings/archiving)
- [稽核資料清理](sps-audit-cleanup.md)
