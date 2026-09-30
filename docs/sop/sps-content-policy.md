# SPS 即時內容原則

## 目的

在支援的工作階段中偵測指定文字或命令，依規則記錄事件、通知或中止連線。

## 適用範圍

以下是 SPS 8.0 LTS 寫法。SSH shell 可監控命令／畫面文字；圖形協定的視窗標題偵測不等於所有畫面文字的即時辨識。

## 前置條件

已建立專用測試 Connection Policy 與 Channel Policy，並確認通知目的地。避免直接編輯由多條正式連線共用的通道原則。

## 操作步驟

1. 到 `Policies > Content Policies` 新增 `Pilot-Content-Alert`。
2. SSH 測試選擇 Screen content，Match 輸入 `PAM_CONTENT_TEST`。有排除需求時再設定 Ignore，避免寬鬆的排除式抵銷偵測。
3. 第一輪只啟用記錄事件及必要通知，先不啟用中止連線；儲存原則。
4. 在測試 Channel Policy 選取這個 Content Policy，確認測試 Connection Policy 引用該 Channel Policy，提交變更。
5. 透過 SPS 建立 SSH 工作階段，在 shell 執行 `printf '%s\n' 'PAM_CONTENT_TEST'`，核對事件與通知。再執行沒有測試字串的命令，確認未誤報。
6. 若需求是阻擋，在隔離測試原則啟用中止連線並重測。正式導入前，由應用負責人確認誤判影響與連線中止後的交易處理。

## 注意事項

官方明示圖形協定的即時內容監控不支援 Arabic 與 CJK，不能承諾繁體中文視窗標題可即時阻擋。辨識採啟發式方法，可能漏判；啟用也會明顯增加效能負擔。

本專案建議先告警再阻擋，並搭配目標系統權限控管。撤回時恢復原 Channel Policy 對應，再用新工作階段驗證。

## 相關文件

- [官方：SPS 8.0 LTS，Content Policies 與限制](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/administration-guide/58)
- [事後 OCR 索引](sps-ocr.md)
