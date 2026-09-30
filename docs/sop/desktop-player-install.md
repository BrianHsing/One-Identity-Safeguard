# Windows 安裝 Safeguard Desktop Player 與回放

## 目的

安裝側錄播放器並驗證已授權的稽核檔案可正常回放。

## 適用範圍

以下依 SPS 8.0 LTS 所附 Safeguard Desktop Player User Guide，示範 Windows 11。播放器套件版本另行記錄，不能直接視為 SPS 韌體版本。

## 前置條件

具備官方下載權限、受管理的工作站，以及可下載測試側錄的稽核權限。加密側錄需另取得核准的解密材料，播放器安裝本身不會授予解密權限。

## 操作步驟

> 截圖範圍：本次連入 SPP／SPS 管理介面，沒有在用戶端執行本工具安裝或播放驗收。以下安裝程序保留原官方版本基準，不以管理網頁截圖冒充安裝精靈。實機已核對項目見[截圖與驗證範圍](environment-evidence.md)。

1. 從 One Identity 支援入口的 SPS 軟體下載取得 Windows 播放器，核對套件版本與來源。
2. 執行安裝程式，在 Setup Preferences 選擇開始功能表及側錄副檔名關聯，確認安裝路徑，閱讀並接受授權條款後完成安裝。
3. 本例使用一般桌面回放流程。若環境仍以 SPP Desktop Client 呼叫播放器，須依官方專章確認安裝位置，不能直接沿用每位使用者的預設路徑。
4. 從 SPS 下載已結束、無敏感資料的測試側錄，先保留原檔，再以播放器開啟；加密檔依介面提供解密金鑰。
5. 使用檔案驗證功能檢查完整性／簽章結果，再測試播放、跳轉時間點與畫面內容。驗證有警告時先釐清，不直接宣稱證據完整。
6. 若需匯出影片，另經資料擁有人核准，保留原始側錄與必要的驗證資訊；交付前遮罩敏感內容。

## 注意事項

匯出影片不等於保留原始側錄全部稽核特性。側錄可能包含畫面、輸入內容及傳輸檔案，工作站與輸出路徑應限制存取，不將私密金鑰與側錄一起寄送。

## 相關文件

- [官方：SPS 8.0 LTS，播放器指南與需求](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/safeguard-desktop-player-user-guide)
- [官方：Windows 安裝步驟](https://support.oneidentity.com/es-es/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0-lts/safeguard-desktop-player-user-guide/2)
- [回專案目錄](../../README.md)
