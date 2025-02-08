# 建立額外的管理者與一般使用者帳號

- 開啟瀏覽器輸入 https://10.16.10.90 開啟 SPP 使用介面，使用預設帳號及密碼登入 admin / Admin123<br>
  ![GITHUB](/images/spp/spp_web/1.png "SPP 使用介面")<br>
- 在左邊功能列將`使用者管理`展開，選擇`使用者`<br>
  ![GITHUB](/images/spp/spp_user/1.png "使用者")<br>
- 首先我們要先建立管理者<br>
  - 點選右邊資訊中的`＋`，新增使用者<br>
  ![GITHUB](/images/spp/spp_user/2.png "新增使用者")<br>
  - 在使用者名稱輸入`sgadmin`，時區選擇`(UTC+08:00) Taipei`，點選按鈕`下一步`<br>
  ![GITHUB](/images/spp/spp_user/3.png "使用者名稱")<br>
  - 在密碼欄位輸入密碼`1qaz@WSX`，並且勾選`密碼永不過期`<br>
  ![GITHUB](/images/spp/spp_user/4.png "輸入密碼")<br>
  - 由於這個帳號是管理者，點選上方頁籤`權限`，點選`全選`，完成後點選按鈕`確定`<br>
  ![GITHUB](/images/spp/spp_user/5.png "帳號是管理者")<br>
  - 完成後就可以看到建立好的使用者，完成後右上角點選`X`關閉即可<br>
  ![GITHUB](/images/spp/spp_user/6.png "建立好的使用者")<br>
- 再來要建立一般使用者<br>
  - 一樣點選右邊資訊中的`＋`，新增使用者，在使用者名稱輸入`u01`，時區選擇`(UTC+08:00) Taipei`，點選按鈕`下一步`<br>
  ![GITHUB](/images/spp/spp_user/7.png "新增使用者")<br>
  - 在密碼欄位輸入密碼`1qaz@WSX`，並且勾選`密碼永不過期`，完成後點選按鈕`確定`<br>
  ![GITHUB](/images/spp/spp_user/8.png "輸入密碼")<br>
  - 完成後就可以看到建立好的使用者，完成後右上角點選`X`關閉即可<br>
  ![GITHUB](/images/spp/spp_user/9.png "建立好的使用者")<br>
  - 後續還要再建立一個帳號`a01`，按照上述做法執行即可<br>
- 完成此步驟後，可以看到使用者列表有`sgadmin`、`u01`、`a01`<br>
  ![GITHUB](/images/spp/spp_user/10.png "使用者列表")<br>