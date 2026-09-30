# SPP 新增納管帳戶

## 目的

將既有 Windows、Linux 登入帳戶加入密碼保險箱，供後續存取原則使用。SPP 使用者是申請人；資產帳戶則是登入目標主機的身分，兩者不可混用。

## 適用範圍

以下是 SPP 8.0 LTS Web 用戶端寫法，延續本專案的 WinSrv／LoginUser 與 ubuntu／loginuser 範例。新增納管紀錄不會替作業系統建立使用者。

## 前置條件

已完成[新增資產](../../spp_asset.md)，操作者具有 Asset Administrator 或適當分割區委派權限。目標帳戶已存在，且有 RDP 或 SSH 登入權限。先確認目標帳戶沒有尚未盤點的服務、排程或應用程式相依性。

## 操作步驟

1. 開啟 `Asset Management > Accounts`，選擇 `New Account`，選取 WinSrv 資產。
2. 在 `General` 輸入 `LoginUser`，以描述註明擁有人與用途。本例是本機帳戶；網域帳戶應從目錄資產選取，不要在每台成員伺服器重建同一份帳戶紀錄。
3. 在管理設定確認有效的 Password Profile。先使用不會自動變更密碼的測試設定檔，避免繼承分割區預設排程後立即輪替。
4. 啟用此帳戶的 Session Request；若沒有取出密碼的業務需求，不另外啟用 Password Request。儲存後，使用帳戶密碼設定功能登錄目標目前的密碼，不要把「設定保險箱內的密碼」當成已完成目標主機的密碼變更。
5. 對 ubuntu 重複上述步驟，輸入 `loginuser`，留意 Linux 名稱大小寫。
6. 若資產已完成[服務帳戶設定](spp-service-account.md)，執行 `Check Password`，確認成功並保留作業時間與結果。資產驗證類型仍為 None 時，不把新增成功視為自動密碼管理已驗證。
7. 完成[新增權利與存取原則](spp-entitlements.md)，用 u01 申請、a01 核准，分別測試 RDP 與 SSH。

## 注意事項

服務帳戶與供人員申請的登入帳戶應分開。密碼不寫入文件、截圖或工單。若輸入錯誤，修正保險箱中的值後再檢查，避免連續驗證造成目標帳戶鎖定。

驗收應記錄資產、帳戶、申請編號與側錄識別資訊，確認登入的是預期主機及使用者。

## 相關文件

- [官方：SPP 8.0 LTS，Adding an account](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/53)
- [官方：帳戶存取服務與設定檔](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/79)
- [回專案目錄](../../README.md)
