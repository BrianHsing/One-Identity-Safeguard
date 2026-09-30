# SPP 新增權利與存取原則

## 目的

讓 u01 僅能申請指定主機的工作階段，並由 a01 核准。權利（Entitlement）決定誰能申請；存取要求原則決定帳戶範圍、存取方式與簽核流程。

## 適用範圍

以下是 SPP 8.0 LTS Web 用戶端寫法；RDP／SSH 連線使用已整合的 SPS。

## 前置條件

sgadmin 已獲授 Security Policy Administrator 權限；u01、a01 與[納管帳戶](spp-account-management.md)已建立。SPP 與 SPS 整合完成，目標帳戶已啟用 Session Request。

## 操作步驟

1. 開啟 `Security Policy Management > Entitlements`，新增 `Demo-Remote-Access`。
2. 在該權利的 `Users` 加入 u01。a01 作為核准人，不因核准需求而加入申請人清單。
3. 在 `Access Request Policies` 新增 `Demo-Windows-RDP`，Access Type 選擇 RDP。在 Scope 僅加入 WinSrv 的 LoginUser 及本次需要的目標範圍。
4. 設定工作階段使用的 SPS 連線設定，與 SPS 上已驗證的連線原則對應。
5. Web 介面的流程設定分成 Requester、Approver、Reviewer。Requester 設定申請理由及存取期限；本專案測試建議為 1 小時，這是示範值，不是產品預設。
6. Approver 選擇 `Approvals Required`，Qty 設為 1，核准人加入 a01，不使用 Auto-Approved。若啟用事後覆核，另指定實際覆核人。
7. 儲存後建立 `Demo-Linux-SSH`，Access Type 選 SSH，Scope 僅加入 ubuntu 的 loginuser；套用同樣的申請與核准流程。
8. 用 u01 測試：核准前不可啟動、a01 核准後可啟動。再用未獲授此權利的測試使用者確認看不到該申請範圍。
9. 登出目標並歸還申請後，核對申請歷程與 SPS 側錄，確認實際目標、登入帳戶和操作人一致。

## 注意事項

不要為了讓帳戶出現在清單而擴大為所有資產／帳戶。若另有重疊原則，須檢查使用者實際可用的全部權利，避免其他原則提供較寬鬆的途徑。失敗時先移除測試權利中的 u01 或停用該原則，保留歷程供查核。

## 相關文件

- [官方：SPP 8.0 LTS，Entitlements](https://support.oneidentity.com/de-de/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/99)
- [官方：Requester／Approver／Reviewer 設定](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/102)
- [使用者申請、核准與歸還](spp-session-workflow.md)
