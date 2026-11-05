# KB-006：SPP 資產、帳號與密碼 CSV 匯入

## 適用範圍與證據

本文整理 SQL Server 資產的 CSV 匯入經驗。使用者已確認：修正分割區名稱與服務帳戶認證類型後，資產測試成功；帳號範例及四欄密碼匯入亦成功。這些是案例回報，未由本文作者重新操作設備。案例未記錄 SPP 完整版本，不套用儲存庫其他文章的版本。

本次公開範例僅完成靜態驗證，尚未實際匯入 SPP。所有 IP 使用文件專用網段，分割區與帳號均為示意值，密碼全部留白。檔案分開提供於 [CSV 範例目錄](../../examples/spp-csv-import/README.md)。

欄位依本次提供範本的可讀標頭整理，保留欄位順序並排除表格預覽額外產生的 `index`。原始附件下載因 HTTPS 憑證過期而失敗，未完成原始位元組比對；使用前仍須以目標 SPP 的 Download Template 核對。帳號來源為已填資料的修訂檔，只取標頭，不收錄來源資料列。

## 匯入順序

1. 記錄 SPP 版本、操作人員權限與目標分割區；確認分割區已存在且操作人員可使用。
2. 從各匯入功能下載當前版本範本，對照欄名、順序及型別，再填資產資料。
3. 在 Assets 匯入資產，先測試少量資料，查看結果與錯誤，確認名稱、位址、平台及分割區。
4. 在 Accounts 選擇 Import Accounts，建立已存在資產下的帳號；確認每個資產都有預期帳號。
5. 在受控環境填妥密碼檔後，選擇 Import Passwords，依帳號、資產與分割區定位既有帳號。空白密碼範例不可直接執行。
6. 每階段核對成功與失敗筆數，完成少量驗證後再擴大批次。不要把上一階段未成功的物件直接帶入下一階段。

官方 7.4.1 文件將 Import Accounts 與 Import Passwords 分開，並要求先匯入帳號；介面與權限仍依現場版本確認：[Importing objects](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/7.4.1/user-guide/importing-objects)。

## 欄位與填寫規則

### 資產：20 欄

完整順序見 [assets.example.csv](../../examples/spp-csv-import/assets.example.csv)。

| 欄位 | 本例規則 |
|---|---|
| `Description`、`PlatformDisplayName` | 均填 `SQL Server`；Description 是說明文字，平台由 PlatformDisplayName 指定 |
| `Name` | SPP 資產名稱；本例刻意以文件用 IP 作名稱 |
| `NetworkAddress` | 連線位址；不必與 Name 相同，但帳號檔必須引用 Name |
| `AssetPartitionName` | 必須與 SPP 現有分割區名稱一致，不可只靠匯入檔建立分割區 |
| `ConnectionProperties/UseSslEncryption`、`ConnectionProperties/VerifySslCertificate` | 布林欄，填 TRUE 或 FALSE；本例留白，使用前依版本、平台與 TLS 要求設定，留白不代表 FALSE |
| `ConnectionProperties/ServiceAccountCredentialType` | 本例填 `None`，不要填 FALSE |
| 服務帳戶名稱、網域、密碼、金鑰及其他選填欄 | 本例未提供，保持空白；不要整列以 FALSE 補值 |
| `ConnectionProperties/Port` | 本例留白；依實際 SQL Server 連接埠與平台設定確認 |

`None` 表示此處未選用服務帳戶認證；本次以此值完成資產建檔，不代表 SQL Server 允許匿名登入，也不代表密碼檢查、變更或代登已可用。後續如需管理密碼，必須另設適用認證、權限與連線設定並驗證。不要將本次建檔修正當成所有平台的通用認證設定。

### 帳號：6 欄

```csv
Name,DistinguishedName,DomainName,Description,Asset/Name,Asset/AssetPartitionName
```

`Name` 是受管帳號名稱，不是資產名稱。`Asset/Name` 必須等於資產 CSV 的 `Name`，`Asset/AssetPartitionName` 必須等於該資產的分割區。此 SQL 帳號示意未填 DistinguishedName 與 DomainName；目錄帳號情境需另核對，不直接套用。

本例兩個資產、各兩個帳號，共四列，先放 `SqlDemo2` 的全部資產，再放 `SqlDemo4`。每組 IP 按數值順序排列；排序是交付習慣，不是 SPP 的必要條件。一般化批次為 N 個資產 × 2 個帳號 = 2N 列，匯入前確認無重複組合。

### 密碼：4 欄

```csv
Name,Asset/Name,Asset/AssetPartitionName,Password
```

前三欄須與帳號資料一致。`Password` 是待匯入的受管帳號密碼，不是資產的服務帳戶密碼；兩者不可混填。客戶必須填妥實際密碼後才執行 Import Passwords，不用 `None`、`FALSE` 或示意字串代替密碼。

### CSV 格式

保留範本欄名的斜線 `/`，不要自行改成點號、翻譯或重新排序。官方 7.4 說明欄序可變、欄名必須符合屬性名稱；本 KB 為方便比對，仍保留提供範本的順序：[Creating an import file](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/7.4/user-guide/creating-an-import-file)。

使用逗號分隔 CSV；含逗號、雙引號或換行的值交由標準 CSV 寫入器正確引號處理。試算表另存後重新解析確認，避免另存成分號分隔、刪除尾端空欄、改變文字值或增加列號。pandas 輸出時使用 `index=False`；Excel 左側列號及預覽的 `index` 都不是匯入欄位。名稱欄避免前後空白，不可任意修剪密碼內容。GitHub 儲存的三份 CSV 採 UTF-8 BOM 與 LF；Windows checkout 可能依 Git 設定轉為 CRLF（例如 `core.autocrlf=true`）。請檢查實際匯入檔，目標版本的編碼與換行支援仍須以小批次驗證。

## 本次排錯紀錄

| 現象 | 判斷與修正 | 證據界線 |
|---|---|---|
| 最初兩筆資產回報找不到分割區 | 核對現有分割區名稱、文字空白及可見權限；填入正確名稱 | 本次先修正名稱，再處理下一個錯誤 |
| 後續回報無效服務帳戶認證類型 | 文字／認證欄被誤填 FALSE；清除不適用值，認證類型改為 None | 使用者確認修正後資產測試成功 |
| 帳號與密碼需要分開匯入 | 先建帳號，再以四欄檔案匯入密碼 | 使用者確認帳號與密碼測試成功 |

若仍找不到資產或帳號，核對三欄組合，不只比 IP；資產顯示名稱可能不同於連線位址。若有型別錯誤，先看完整欄名與該列資料，不要把所有空欄改成 FALSE。若只部分成功，保存結果並隔離失敗列，確認已存在物件後再重試；本文未驗證重複匯入的覆寫或跳過行為。

## 驗證與資料處理

- 匯入前：解析欄數（20／6／4）、欄名與順序，確認無 index、無重複鍵；帳號引用的資產都存在，密碼列能唯一對應帳號。
- 匯入後：核對每階段的結果筆數及失敗原因；抽查平台、分割區、資產名稱和帳號歸屬。匯入成功不等於目標密碼變更成功，連線、密碼檢查與變更須另依授權測試。
- 驗收紀錄：保留版本、批次名稱、時間、筆數與去識別錯誤摘要，不記錄實際密碼。
- 填入密碼的 CSV 為明文機密，僅在受控環境儲存與傳遞；不得提交 Git、貼入日誌或一般訊息。完成後依客戶政策清理下載副本、暫存及備份。
- 回復：此流程不能以「重新匯入空白密碼」復原。先盤點本次新增物件及影響，再依變更程序處理；既有帳號密碼的復原須另備核准方案。

[範例與使用說明](../../examples/spp-csv-import/README.md) · [KB 目錄](README.md)
