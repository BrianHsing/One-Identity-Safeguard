# SPP 使用者申請、核准與歸還工作階段

## 目的

完成 u01 申請、a01 核准、RDP／SSH 連線與稽核覆核的完整流程。

## 適用範圍

以下是 SPP 8.0 LTS Web 用戶端搭配 SPS 的寫法。

## 前置條件

已完成[權利與存取原則](spp-entitlements.md)。使用者電腦可連到 SPP 與 SPS，並準備受支援的 RDP／SSH 用戶端。要直接啟動外部用戶端時完成[SCALUS 設定](scalus-install.md)。

## 操作步驟

1. u01 登入 SPP，選取可用資產、帳戶與 RDP 或 SSH 存取方式，填入用途、開始時間及需要的期限後送出。
2. 核對申請狀態與申請編號。尚未核准或尚未到開始時間時，不應取得可用的連線。
3. a01 登入自己的工作階段，在 Approvals 檢查申請人、目標、帳戶、原因與時間；符合授權才核准，不符合則拒絕並註明原因。
4. u01 回到 My Requests，待申請可用後啟動工作階段。RDP 可使用下載的 RDP 啟動檔；直接啟動按鈕需要對應協定處理程式。SSH 使用介面提供的啟動或連線資訊。
5. 若標準 SPP 發起的 RDP 連線要求輸入啟動密碼，依官方本版說明使用非空白值；官方範例為 `sg`。這不是目標帳戶密碼。若原則選 User Supplied，則須依介面提供實際要求的使用者憑證，兩種情境不可混用。
6. 確認實際主機與登入帳戶，執行核准範圍內的工作；完成後登出目標，再回 SPP 選擇 Check in 歸還。
7. 稽核人員核對申請歷程與 SPS 側錄，若原則要求 Reviewer，完成事後覆核。驗收另測拒絕申請及期限屆滿後無法新啟動工作階段。

## 注意事項

不共用申請人與核准人的登入工作階段。關閉 RDP 視窗不一定等於登出，也不等於已歸還 SPP 申請。連線檔、一次性連線資訊及 Token 不放入工單附件。

## 相關文件

- [官方：SPP 8.0 LTS，工作階段啟動與歸還](https://support.oneidentity.com/fr-fr/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/18)
- [回專案目錄](../../README.md)
