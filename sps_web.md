# 使用瀏覽器登入 SPS 初始設定

> 截圖為 SPS 8.0 舊示範，授權期限與組織資料不可沿用。網路頁的 NTP 未填不是建議配置，正式環境須設定可信任時間來源。自我簽署憑證僅為初始設定，正式信任部署應使用符合主機名稱且受用戶端信任的憑證。

- 使用瀏覽器登入 SPS 網址 ````https://<CUSTOMER_SPS_HOST>````<br>
- 第一步驟是將舊有組態檔匯入，全新安裝請忽略，直接點選下一步<br>
  ![GITHUB](/images/sps/sps_web/1.png "忽略")<br>
- 第二步驟是將授權上傳，勾選````I have read and agree with the terms and conditions:````，使用 One Identity 授權窗口核發、適用此環境與版本的 SPS 授權檔，上傳後點選下一步<br>
  ![GITHUB](/images/sps/sps_web/2.png "授權上傳")<br>
- 設定網路組態，設定實體網卡、預設閘道、主機名稱(只能英文小寫)、網域名稱(必要）、DNS 伺服器位址、SMTP 伺服器與管理者電子郵件<br>
  ![GITHUB](/images/sps/sps_web/3.png "設定網路組態")<br>
- 設定管理者與 Root 密碼<br>
  ![GITHUB](/images/sps/sps_web/4.png "設定管理者")<br>
- 輸入組織與單位名稱，點選 ````Generate Certificate````，建立 SPS 的主機自我簽署憑證<br>
  ![GITHUB](/images/sps/sps_web/5.png "建立 SPS 的主機自我簽署憑證")<br>
- 確認資訊無誤後點選 Finish 開始套用。下圖仍顯示 Applying configuration，不能據此判定完成；等待套用結束並重新登入，核對網路、時間與授權狀態<br>
  ![GITHUB](/images/sps/sps_web/6.png "完成")<br> 

  [SPS 側錄模組整合 SPP 密碼模組](/sppsps.md)<br>
[官方 SPS 8.0 LTS 管理指南](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/administration-guide)。
