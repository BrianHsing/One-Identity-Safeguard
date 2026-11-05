# SPP CSV 匯入範例

請先閱讀 [KB-006](../../docs/kb/spp-csv-import.md)。本目錄提供去識別化範例，尚未實際匯入 SPP；使用前比對目標版本的 Download Template。

| 檔案 | 欄數 | 資料列數 | 用途 |
|---|---:|---:|---|
| [assets.example.csv](assets.example.csv) | 20 | 2 | SQL Server 資產建檔 |
| [accounts.example.csv](accounts.example.csv) | 6 | 4 | 每個資產兩個帳號 |
| [passwords.example.csv](passwords.example.csv) | 4 | 4 | 客戶填寫密碼後匯入 |

1. 將檔案複製到儲存庫以外的受控工作目錄；不要把填妥的客戶資料放回此目錄。
2. 將 `Demo-Partition` 替換成既有分割區，將 `192.0.2.10`、`192.0.2.20` 替換為實際資產名稱與位址，並同步調整三份檔案。這兩個 IP 為文件專用值，不能用來驗證實際連線。
3. 將 `SqlDemo2`、`SqlDemo4` 換成實際帳號。範例先列第一組全部資產，再列第二組；組內按 IP 數值排序。
4. 資產認證類型 None 僅用於本例建檔；布林與其他選填欄留白，需依目標平台確認。TLS、服務帳戶及連接埠設定另行核對。
5. 依資產 → 帳號 → 密碼的順序先少量測試。密碼檔全部留白，必須由客戶填入正確密碼後才能匯入。

GitHub 儲存的三份檔案採 UTF-8 BOM、LF、逗號分隔，不含額外 index。Windows checkout 可能依 Git 設定轉為 CRLF（例如 `core.autocrlf=true`）；使用前請檢查實際匯入檔，並以小批次確認目標版本支援。欄位順序依本次範本可讀標頭，原始位元組尚未比對，限制與案例成功證據詳見 KB。密碼含逗號、雙引號或換行時，請使用標準 CSV 工具輸出，勿手動拼接。

填入真實密碼後僅在受控環境處理，完成後依客戶政策清理。不可將密碼範例的空值當成清除或重設密碼的指令。
