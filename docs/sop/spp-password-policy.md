# SPP 密碼原則與設定檔

## 目的

分別管理密碼組成規則、檢查排程與變更排程，避免直接修改共用設定而影響所有帳戶。

## 適用範圍

以下是 SPP 8.0 LTS 的納管帳戶 Password Profile 寫法，不是 SPP 平台使用者的登入密碼原則。

## 前置條件

具備 Asset Administrator 或適當分割區權限。先盤點目標作業系統與應用程式允許的密碼長度、字元及密碼歷程限制。

## 操作步驟

1. 在 `Asset Management > Profiles > View Password Profile Components > Account Password Rules` 新增專用規則，設定長度與必要字元類型，排除目標不接受的字元。
2. 在同一元件管理頁建立 Check Password 與 Change Password 設定。首次測試不要安排尚未核准的自動變更時段。
3. 到 `Asset Management > Profiles > Password Profiles` 建立 `Pilot-Password-Profile`，分別選取檢查、變更與帳戶密碼規則，儲存。
4. 僅將一個測試帳戶明確指派至該設定檔，確認有效設定沒有誤用到整台資產或整個分割區。
5. 完成一次手動變更、檢查、工作階段登入與相依服務驗證後，再啟用正式排程。
6. 記錄變更前後設定檔名稱、套用對象、時區與維護時段。若需撤回，恢復原設定檔指派；已變更的密碼不會隨之還原。

## 注意事項

官方規則的繼承順序為：帳戶明確指派優先，其次是資產設定檔，再其次是分割區預設。修改資產設定檔不會覆蓋帳戶明確指派的設定。

SPP 可產生的長度不代表目標能完整接收；部分平台可能截斷密碼。請用實際登入驗證，避免僅看變更工作成功。

## 相關文件

- [官方：SPP 8.0 LTS，Account Password Rules](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/81)
- [官方：Password Profile 繼承](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/66)
- [官方：建立 Password Profile](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/79)
