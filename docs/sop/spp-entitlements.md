# SPP 新增權利與存取原則

## 目的

讓 u01 僅能申請指定主機的工作階段，並由 a01 核准。權利（Entitlement）決定誰能申請；存取要求原則決定帳戶範圍、存取方式與簽核流程。

## 適用範圍

畫面與中文操作名稱於 2026-09-30 以 SPP 9.0.0.2807 Web 用戶端核對；文末 8.0 LTS 官方文件作為原理參考，不代表所有 9.0 行為均已驗證。 RDP／SSH 使用已整合的 SPS。

## 前置條件

sgadmin 已獲授 Security Policy Administrator 權限；u01、a01 與[納管帳戶](spp-account-management.md)已建立。SPP 與 SPS 整合完成，目標帳戶已啟用 Session Request。

## 操作步驟

### 從權利進入存取原則

開啟 `安全性原則管理 > 權利`，新增權利或開啟既有權利。權利本身有「一般」、「存取要求原則」、「使用者」與「歷程記錄」；申請人放在權利的「使用者」，核准人則在原則的「工作流程」。

在「存取要求原則」新增或開啟一筆原則。「一般」先選「工作階段」，再選 RDP／SSH；RDP 應用程式是另一種用途，不能只靠命名區分。

![存取要求原則的工作階段類型](../../images/sop/spp-access-policy.jpg)

圖 1：現場 Demo 權利中的 RDP 原則，僅檢視。範圍與流程仍需個別確認。

到 `工作流程 > 核准者`，選「需要核准」、設定「數量」，再按「瀏覽使用者」選取核准人。下方的通知收件人不等於有核准權限的人。

![需要核准與核准人數設定](../../images/sop/spp-approver.jpg)

圖 2：現場數量為 1、核准人為 sgadmin，裁去通知信箱；本文教學的 a01 是規劃範例，並未在現場替換。

特別檢查「要求者」分頁的緊急存取設定。現場 Demo 允許緊急存取且勾選忽略時間限制，不能拿這筆既有原則證明「任何情況都必須先核准」。正式測試須使用符合核准制度的專用原則，另測緊急例外；本次未改動這些選項。

### 實施與驗收程序（尚未實跑）

1. 開啟 `安全性原則管理 > 權利`，新增 `Demo-Remote-Access`。
2. 在該權利的「使用者」 加入 u01。a01 作為核准人，不因核准需求而加入申請人清單。
3. 在「存取要求原則」 新增 `Demo-Windows-RDP`，「一般」選擇「工作階段」，類型選 RDP。在 Scope 僅加入 WinSrv 的 LoginUser 及本次需要的目標範圍。
4. 設定工作階段使用的 SPS 連線設定，與 SPS 上已驗證的連線原則對應。
5. Web 介面的流程設定分成 Requester、Approver、Reviewer。Requester 設定申請理由及存取期限；本專案測試建議為 1 小時，這是示範值，不是產品預設。
6. Approver 選擇 `Approvals Required`，Qty 設為 1，核准人加入 a01，不使用 Auto-Approved。若啟用事後覆核，另指定實際覆核人。
7. 儲存後建立 `Demo-Linux-SSH`，「一般」選擇「工作階段」，類型選 SSH，Scope 僅加入 ubuntu 的 loginuser；套用同樣的申請與核准流程。
8. 使用未開放緊急存取的專用測試原則，用 u01 測試：核准前不可啟動、a01 核准後可啟動。再用未獲授此權利的測試使用者確認看不到該申請範圍。
9. 登出目標並歸還申請後，核對申請歷程與 SPS 側錄，確認實際目標、登入帳戶和操作人一致。

## 注意事項

不要為了讓帳戶出現在清單而擴大為所有資產／帳戶。若另有重疊原則，須檢查使用者實際可用的全部權利，避免其他原則提供較寬鬆的途徑。失敗時先移除測試權利中的 u01 或停用該原則，保留歷程供查核。

## 相關文件

- [實機截圖與驗證範圍](environment-evidence.md)
- [官方：SPP 8.0 LTS，Entitlements](https://support.oneidentity.com/de-de/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/99)
- [官方：Requester／Approver／Reviewer 設定](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/102)
- [使用者申請、核准與歸還](spp-session-workflow.md)
