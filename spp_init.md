# 使用 Console 初始 SPP 設定<br>

> 截圖為 SPP 7.0.0.18433 舊版初始化。預設帳密僅限全新設備初次設定，完成後立即更換；日常管理使用具備適當角色的個人帳戶。

- 點選 [Begin Initial Setup] 初始化 SPP<br>
  ![GITHUB](/images/spp/spp_init/1.png "初始化 SPP")<br>
- 輸入預設帳號密碼 admin / Admin123<br>
  ![GITHUB](/images/spp/spp_init/2.png "輸入預設帳號密碼")<br>
- 輸入 Appliance 名稱，此範例名稱為 SPP-Demo<br>
- 填入 Windows Licensing，依授權方式使用 KMS 或產品金鑰；作業系統授權與 SPP 產品授權分開確認，不以未填入等同具有固定天數的試用權利<br>
- 輸入規劃好的可信任 NTP 位址，並於完成後確認時間同步，此範例使用 10.16.10.105 作為 NTP Server<br>
  ![GITHUB](/images/spp/spp_init/3.png "輸入初始化 SPP資訊")<br>
- 輸入實際使用的網路介面資訊，IPv4、IPv4 Subnet Mask、IIPv4 Gateway、DNS Server 爲必要條件，完成後點選 Save<br>
  - 此範例使用 IPv4:10.16.10.90
  - IPv4 Subnet Mask:255.255.255.0
  - IPv4 Gateway:10.16.10.253
  - DNS Server:10.16.10.105
  ![GITHUB](/images/spp/spp_init/4.png "輸入實際使用的網路介面資訊")<br>
- 後續 SPP 會執行初始化作業<br>
  ![GITHUB](/images/spp/spp_init/5.png "執行初始化作業")<br>
- 點選 Continue 結束初始化畫面；接著確認管理介面可登入、DNS／NTP 正常並完成授權<br>
  ![GITHUB](/images/spp/spp_init/6.png "點選 Continue")<br>
繼續[使用瀏覽器登入 SPP 進行初始設定](/spp_web.md)<br>
[SPP 8.0 LTS 官方初始化與授權說明](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/4)。
