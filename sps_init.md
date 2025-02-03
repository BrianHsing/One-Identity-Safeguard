# 使用 Console 初始 SPS 設定<br>

- 使用 Console 啟動 SPS 時，會看到主選單畫面，選擇 Installer 開始安裝<br>
  ![GITHUB](/images/sps/sps_init/1.png "使用 Console 啟動 SPS")<br>
- 完成安裝後，會看到登入畫面<br>
  ![GITHUB](/images/sps/sps_init/2.png "完成安裝")<br>
- 輸入預設帳號密碼 root / default 進入主選單<br>
  ![GITHUB](/images/sps/sps_init/3.png "輸入預設帳號密碼")<br>
- 選擇 Shells<br>
  ![GITHUB](/images/sps/sps_init/4.png "選擇 Shells")<br>
- 選擇 Core shell<br>
  ![GITHUB](/images/sps/sps_init/5.png "選擇 Core shell")<br>
- 設定 eth0 的網路介面，設定固定 IP、網路遮罩 ````ifconfig eth0 <IP-address> netmask 255.255.255.0```` <br>
  ![GITHUB](/images/sps/sps_init/6.png "虛設定 eth0 的網路介面")<br>
- 設定 eth0 的預設閘道 ````route add default gw <IP-of-default-gateway> ```` <br>
  ![GITHUB](/images/sps/sps_init/7.png "設定 eth0 的預設閘道")<br>
- 輸入 exit 離開 Core shell 介面<br>
  ![GITHUB](/images/sps/sps_init/8.png " 輸入 exit 離開")<br>
- 選擇 Logout 登出<br>
  ![GITHUB](/images/sps/sps_init/9.png "選擇 Logout")<br>

  - [使用瀏覽器登入 SPS](/sps_web.md)<br>