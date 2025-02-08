# 建立額外的管理者與一般使用者帳號

1. **開啟 SPP 使用介面**
  - 開啟瀏覽器，輸入 `https://10.16.10.90` 以開啟 SPP 使用介面。
  - 使用預設帳號及密碼登入：`admin / Admin123`。
  ![GITHUB](/images/spp/spp_web/1.png "SPP 使用介面")

1. **進入使用者管理**
  - 在左邊功能列將 `使用者管理` 展開，選擇 `使用者`。
  ![GITHUB](/images/spp/spp_user/1.png "使用者")

1. **建立管理者帳號**
  - 點選右邊資訊中的 `＋`，新增使用者。
  ![GITHUB](/images/spp/spp_user/2.png "新增使用者")
  - 在使用者名稱輸入 `sgadmin`，時區選擇 `(UTC+08:00) Taipei`，點選按鈕 `下一步`。
 ![GITHUB](/images/spp/spp_user/3.png "使用者名稱")
  - 在密碼欄位輸入密碼 `1qaz@WSX`，並且勾選 `密碼永不過期`。
  ![GITHUB](/images/spp/spp_user/4.png "輸入密碼")
  - 由於這個帳號是管理者，點選上方頁籤 `權限`，點選 `全選`，完成後點選按鈕 `確定`。
  ![GITHUB](/images/spp/spp_user/5.png "帳號是管理者")
  - 完成後就可以看到建立好的使用者，完成後右上角點選 `X` 關閉即可。
  ![GITHUB](/images/spp/spp_user/6.png "建立好的使用者")

1. **建立一般使用者帳號**
  - 點選右邊資訊中的 `＋`，新增使用者。
  - 在使用者名稱輸入 `u01`，時區選擇 `(UTC+08:00) Taipei`，點選按鈕 `下一步`。
  ![GITHUB](/images/spp/spp_user/7.png "新增使用者")
  - 在密碼欄位輸入密碼 `1qaz@WSX`，並且勾選 `密碼永不過期`，完成後點選按鈕 `確定`。
  ![GITHUB](/images/spp/spp_user/8.png "輸入密碼")
  - 完成後就可以看到建立好的使用者，完成後右上角點選 `X` 關閉即可。
  ![GITHUB](/images/spp/spp_user/9.png "建立好的使用者")
  - 後續還要再建立一個帳號 `a01`，按照上述做法執行即可。

1. **確認使用者列表**
  - 完成此步驟後，可以看到使用者列表有 `sgadmin`、`u01`、`a01`。
  ![GITHUB](/images/spp/spp_user/10.png "使用者列表")

前往[新增資產](/spp_asset.md)