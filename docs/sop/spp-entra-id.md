# SPP 整合 Microsoft Entra ID

## 目的

透過 SAML External Federation 讓使用者以 Entra ID 登入 SPP，並維持 SPP 端的獨立授權。

## 適用範圍

以下採 SPP 8.0 LTS 與 One Identity KB 4360719 的做法。官方 KB 使用舊稱 Azure AD，本文統一稱 Entra ID；此流程不代表已建立自動使用者佈建。

## 前置條件

準備 SPP Appliance Administrator、可管理企業應用程式的租用戶管理身分，以及一個測試使用者。記錄正式登入 FQDN／VIP、名稱解析與憑證；保留可用的本機緊急管理帳戶。

## 操作步驟

1. 在 SPP `Identity and Authentication` 新增 External Federation，Realm 使用測試使用者的登入尾碼，下載 SPP Federation Metadata。
2. 在 Entra ID 建立非資源庫企業應用程式並設定 SAML 單一登入。Identifier 使用 SPP metadata 的 entityID；Reply URL 登錄實際使用的 `https://<CUSTOMER_SPP_FQDN>/RSTS/Login`。不要自行把 entityID 中的 http 改為 https。
3. 依 KB 設定 NameID 使用 `user.userprincipalname` 或 `user.mail`，並讓 SPP 對應屬性一致。採用 KB 的單一 NameID 做法時，移除額外 claims，避免不同識別值互相衝突。
4. 將測試使用者指派到企業應用程式。下載 Entra ID Federation Metadata XML，匯入 SPP 的 External Federation 提供者並儲存。
5. 將 SPP 測試使用者的驗證提供者及 claim 對應至此設定；若身分來源是 AD，核對 External Federation Authentication 屬性使用 mail 或 userPrincipalName。
6. 用獨立瀏覽器從 SPP 發起登入，確認導向 Entra ID、完成驗證並回到正確使用者。測試未指派者不能使用，且成功登入者只具備預期權利。
7. 建立簽署憑證到期與 metadata 更新責任，留存測試日期及不含權杖內容的結果紀錄。

## 注意事項

SPP 要求 SAML Response 或 Assertion 簽署且不加密；憑證輪替時須更新相應 metadata。登入成功不會自動取得資產存取權。[官方驗證規格](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/154)

本專案建議先以測試群組套用 MFA／條件式存取，授權與原則由租用戶管理者依實際方案確認。不要在文件中附完整 SAML assertion、簽章、Token 或含個資的 metadata 截圖。

## 相關文件

- [官方：KB 4360719，Entra ID Federation 設定](https://support.oneidentity.com/one-identity-safeguard-for-privileged-passwords/kb/4360719/configuring-microsoft-s-azure-ad-federation-with-safeguard)
- [AD 登入整合](spp-active-directory.md)
- [權利設定](spp-entitlements.md)
