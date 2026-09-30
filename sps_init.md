# 使用 Console 初始 SPS 設定<br>

> 以下為 SPS 8.0 LTS 首次設定流程。root／default 與 Core shell 的 ifconfig、route 步驟僅適用尚未完成 Welcome Wizard 的設備；已上線設備應使用產品網路設定頁變更。255.255.255.0 是舊示範遮罩，請換成核准的網段設定。Welcome Wizard 須填入相同規劃位址，不能把暫時 shell 設定當成持久設定。

- 使用 Console 啟動 SPS 時，會看到主選單畫面，選擇 Installer 開始安裝。確認安裝目標為新建專用 VM；安裝程式要求輸入 YES 時會清除所連接磁碟資料，不可用於已有資料的設備<br>
  ![GITHUB](/images/sps/sps_init/1.png "使用 Console 啟動 SPS")<br>
- 完成安裝後，會看到登入畫面<br>
  ![GITHUB](/images/sps/sps_init/2.png "完成安裝")<br>
- 輸入預設帳號密碼 root / default 進入主選單，選擇 Shells<br>
  ![GITHUB](/images/sps/sps_init/3.png "選擇 Shells")<br>
- 選擇 Core shell<br>
  ![GITHUB](/images/sps/sps_init/4.png "選擇 Core shell")<br>
- 設定 eth0 的網路介面，設定固定 IP、網路遮罩 ````ifconfig eth0 <CUSTOMER_SPS_IPV4> netmask 255.255.255.0```` <br>
  ![GITHUB](/images/sps/sps_init/5.png "虛設定 eth0 的網路介面")<br>
- 設定 eth0 的預設閘道 ````route add default gw <CUSTOMER_GATEWAY_IPV4> ```` <br>
  ![GITHUB](/images/sps/sps_init/6.png "設定 eth0 的預設閘道")<br>
- 輸入 exit 離開 Core shell 介面<br>
- ![GITHUB](/images/sps/sps_init/7.png "輸入 exit 離開")<br>
- 選擇 Logout 登出<br>
  ![GITHUB](/images/sps/sps_init/8.png "選擇 Logout")<br>

[使用瀏覽器登入 SPS](/sps_web.md)<br>
[官方首次連線與初始 IP 設定](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/administration-guide/the-welcome-wizard-and-the-first-login/the-initial-connection-to-one-identity-safeguard-for-privileged-sessions-sps/creating-an-alias-ip-address-linux)。
