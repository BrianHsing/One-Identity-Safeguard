# 使用瀏覽器登入 SPS 初始設定

- 使用瀏覽器登入 SPS 網址 ````https://<你的IP>````<br>
- 第一步驟是將舊有組態檔匯入，全新安裝請忽略，直接點選下一步<br>
  ![GITHUB](/images/sps/sps_web/1.png "忽略")<br>
- 第二步驟是將授權上傳，勾選````I have read and agree with the terms and conditions:````，授權可以在 https://1drv.ms/f/s!AvZb8cMf7gfXhOhH1WXkYWzGFQBFUg 開啟，並且在 License 資料夾找到開頭為 SPS 的 dlv 檔案，上傳後點選下一步<br>
  ![GITHUB](/images/sps/sps_web/2.png "授權上傳")<br>
- 設定網路組態，設定實體網卡、預設閘道、主機名稱(只能英文小寫)、網域名稱(必要）、DNS 伺服器位址、SMTP 伺服器與管理者電子郵件<br>
  ![GITHUB](/images/sps/sps_web/3.png "設定網路組態")<br>
- 設定管理者與 Root 密碼<br>
  ![GITHUB](/images/sps/sps_web/4.png "設定管理者")<br>
- 輸入組織與單位名稱，點選 ````Generate Certificate````，建立 SPS 的主機自我簽署憑證<br>
  ![GITHUB](/images/sps/sps_web/5.png "建立 SPS 的主機自我簽署憑證")<br>
- 確認資訊無誤後，點選 Finish 完成<br>
  ![GITHUB](/images/sps/sps_web/6.png "完成")<br> 

  [SPS 側錄模組整合 SPP 密碼模組](/sppsps.md)<br>