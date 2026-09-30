# SPP 整合 Active Directory 登入

## 目的

讓既有 AD 使用者登入 SPP，再透過 SPP 權利控制申請範圍。AD 登入整合與 AD 特權帳戶密碼納管是不同設定。

## 適用範圍

以下是 SPP 8.0 LTS 的 Identity and Authentication 寫法，處理平台登入，不變更 AD 帳戶密碼。

## 前置條件

Appliance Administrator 與 User Administrator 分工完成提供者及使用者設定。SPP 能解析網域與網域控制站名稱，時間同步正常。準備專用目錄讀取帳戶；官方說明，僅供身分與驗證用途時只需要目錄讀取權限。

## 操作步驟

1. 保留已驗證可登入的本機管理員，記錄網域 FQDN、服務帳戶、憑證信任與允許匯入的測試使用者。
2. 到 `Appliance Management > Safeguard Access > Identity and Authentication` 新增 Active Directory 提供者，輸入目錄連線資料與服務帳戶憑證。
3. 若樹系有多個網域，選取要提供登入的網域，不假設所有網域均自動納入。
4. 測試目錄連線與查詢；若使用 TLS，核對網域控制站憑證、名稱與信任鏈，不以忽略憑證錯誤作為修正。
5. 在使用者管理加入一個目錄測試使用者，核對來源提供者及登入名稱。僅授予測試權利，不授管理權限。
6. 以獨立瀏覽器工作階段選取 AD 提供者登入，確認只看得到指定申請範圍；再測試未獲授權的使用者。
7. 記錄登入、匯入與停用流程，確認離職／停權作業如何同步撤回 SPP 存取權。

## 注意事項

本專案建議先用單一測試使用者，再導入群組。群組匯入不代表存取權已完成，仍須設定 Entitlement。失敗時使用保留的本機管理員調整提供者或使用者對應。

要輪替 AD 特權帳戶，另建立目錄資產與適當重設密碼委派權限，不要擴大本篇的讀取帳戶權限來混用。

## 相關文件

- [官方：SPP 8.0 LTS，Identity and Authentication](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/48)
- [官方：Active Directory 提供者及服務帳戶權限](https://support.oneidentity.com/it-it/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/49)
- [權利設定](spp-entitlements.md)
