# 使用 Console 初始 SPP 設定<br>

- 點選 [Begin Initial Setup] 初始化 SPP<br>
  ![GITHUB](/images/spp/spp_init/1.png "初始化 SPP")<br>
- 輸入預設帳號密碼 admin / Admin123<br>
  ![GITHUB](/images/spp/spp_init/2.png "輸入預設帳號密碼")<br>
- 輸入 Appliance 名稱，此範例名稱為 SPP-Demo<br>
- 填入 SPP 的 Windows Licensing，可已使用 KMS 或是金鑰，若未輸入可使用 90 天試用評估<br>
- 輸入 NTP 的 IP 位址，若無可以忽略不填寫，此範例使用 10.16.10.105 作為 NTP Server<br>
  ![GITHUB](/images/spp/spp_init/3.png "輸入初始化 SPP資訊")<br>
- 輸入實際使用的網路介面資訊，IPv4、IPv4 Subnet Mask、IPv4 Gateway、DNS Server 爲必要條件，完成後點選 Save<br>
  - 此範例使用 IPv4:10.16.10.90
  - IPv4 Subnet Mask:255.255.255.0
  - Pv4 Gateway:10.16.10.253
  - DNS Server:10.16.10.105
  ![GITHUB](/images/spp/spp_init/4.png "輸入實際使用的網路介面資訊")<br>
- 後續 SPP 會執行初始化作業<br>
  ![GITHUB](/images/spp/spp_init/5.png "執行初始化作業")<br>
- 點選 Continue 即可完成<br>
  ![GITHUB](/images/spp/spp_init/6.png "點選 Continue")<br>
繼續[使用瀏覽器登入 SPP 進行初始設定](/spp_web.md)<br>