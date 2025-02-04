# SPS 側錄模組整合 SPP 密碼模組

## SPP 前置作業

- 開啟瀏覽器輸入 https://10.16.10.90 開啟 SPP 使用介面，使用預設帳號及密碼登入 admin / Admin123<br>
  ![GITHUB](/images/spp/spp_web/1.png "SPP 使用介面")<br>
- 左邊功能欄展開````裝置管理````並選擇````外部整合````找到````信任的伺服器、CORS 和重新導向````，點選展開，在````允許的主機````填入````*````，完成後點選儲存<br>
  ![GITHUB](/images/sppsps/1.png "SPP 使用介面")<br>
- 左邊功能欄展開````裝置管理````並選擇````Safeguard 存取````找到````本機登入控制````，將 OAuth2 授予類型選項````授權碼`````、````隱含````、````資源擁有者````勾選，完成後點選儲存<br>
  ![GITHUB](/images/sppsps/2.png "SPP 使用介面")<br>

## SPS 整合設定

- 使用瀏覽器登入 SPS 網址 ````https://<你的IP>````<br>
- 使用您的 SPS 帳號密碼進行登錄 admin / <your password><br>
  ![GITHUB](/images/sppsps/3.png "SPP 使用介面")<br>
- 登入到管理頁面<br>
  ![GITHUB](/images/sppsps/4.png "SPP 使用介面")<br>
- 展開````Basic Settings````選擇````Local Services````勾選````Ｃluster Interface````區域中的 Enable 按鈕，並且在````Listening interface````選擇````default````，完成後點選````Commit````<br>
  ![GITHUB](/images/sppsps/5.png "SPP 使用介面")<br>
- 在````Basic Settings````選擇````Cluster Management````，在右邊的畫面選擇````Create a cluster````<br>
  ![GITHUB](/images/sppsps/6.png "SPP 使用介面")<br>
- 點選````Promote````，在````Promoting as a Central management````視窗中選擇 ok 的按鈕<br>
  ![GITHUB](/images/sppsps/7.png "SPP 使用介面")<br>
  ![GITHUB](/images/sppsps/8.png "SPP 使用介面")<br>
- 完成後，在同個頁面點選````Link SPP Cluster````的按鈕<br>
  ![GITHUB](/images/sppsps/9.png "SPP 使用介面")<br>
- 在````Link Appliance to SPP````視窗中，輸入 SPP 的 IP Address，完成後點選````Link````按鈕<br>
  ![GITHUB](/images/sppsps/10.png "SPP 使用介面")<br>
- 出現 SPP 登入畫面時，登入 admin / Admin123，輸入後點選````登入````<br>
  ![GITHUB](/images/sppsps/11.png "SPP 使用介面")<br>
- 完成後，即可看到````Link to SPP````顯示 The current cluster is joined to Safeguard Privileged Passwords on <your IP> address.，代表已經完成整合<br>
  ![GITHUB](/images/sppsps/12.png "SPP 使用介面")<br>