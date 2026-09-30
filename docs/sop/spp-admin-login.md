# SPP 管理員登入流程

## 目的

確保管理員能以正確且安全的方式登入 One Identity Safeguard for Privileged Passwords（SPP）管理介面。

## 適用範圍

以下是 SPP 8.0 LTS Web 用戶端寫法，適用系統管理員與經授權的稽核人員。

## 前置條件

- 已取得 SPP 管理員帳號及初始密碼
- 用戶端裝置可連線至 SPP 管理 IP
- 使用符合該版官方系統需求且仍受維護的瀏覽器，不將固定舊版號當成通用門檻。

## 操作步驟

1. 開啟瀏覽器，前往 `https://<CUSTOMER_SPP_FQDN>/`，確認名稱與憑證信任正常。
2. 選擇正確的登入提供者，輸入個人管理帳號與密碼；External Federation 依導向頁面完成登入。
3. 若環境啟用多因素驗證（MFA），依提示完成第二因素驗證。
4. 登入成功後，畫面將導向 SPP 儀表板（Dashboard）。
5. 確認右上角顯示正確的登入帳號名稱。

## 注意事項

- 鎖定次數與期間依 SPP 本機登入控制或外部身分提供者設定，不假定為固定 5 次。
- 請勿使用公用電腦或不受信任的網路環境登入。
- 工作階段逾時依實際設定，離開前儲存作業並登出。

## 相關文件

- [SPP 初始化設定](../../spp_init.md)
- [SPP Web 介面說明](../../spp_web.md)
- [官方：SPP 8.0 LTS 管理指南](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0-lts/administration-guide)
