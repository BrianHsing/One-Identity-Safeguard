# SPS 側錄模組整合 SPP 密碼模組

> 本篇為 SPP／SPS 8.0 歷史整合示範。操作前備份並評估既有原則：連結可能覆寫 safeguard_default；8.0 官方流程不提供解除連結。Central management 是管理角色，不等於已建置高可用性。

## SPP 前置作業

- 開啟瀏覽器輸入 https://10.16.10.90 開啟 SPP 使用介面，使用具備整合所需管理角色的帳戶登入<br>
  ![GITHUB](/images/spp/spp_web/1.png "SPP 使用介面")<br>
- 左邊功能欄展開````裝置管理````並選擇````外部整合````找到````信任的伺服器、CORS 和重新導向````，點選展開，在「允許的主機」填入核准的 SPS 主機名稱或 IP，不含 scheme、port 或 path。下圖的 `*` 是不限制主機的舊示範，不應沿用<br>
  ![GITHUB](/images/sppsps/1.png "SPP 使用介面")<br>
- 左邊功能欄展開````裝置管理````並選擇````Safeguard 存取````找到````本機登入控制````，保留預設 Authorization Code with PKCE；除非明確的自訂整合需求，不啟用額外授予類型。下圖同時勾選其他類型為舊示範，不是整合必要條件<br>
  ![GITHUB](/images/sppsps/2.png "SPP 使用介面")<br>

## SPS 整合設定

- 使用瀏覽器登入 SPS 網址 ````https://<CUSTOMER_SPS_HOST>````<br>
- 使用您的 SPS 帳號密碼進行登錄 具備適當角色的管理帳戶<br>
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
- 出現 SPP 登入畫面時，使用具備適當角色的 SPP 管理帳戶登入，輸入後點選````登入````<br>
  ![GITHUB](/images/sppsps/11.png "SPP 使用介面")<br>
- 完成後，即可看到````Link to SPP````顯示 The current cluster is joined to Safeguard Privileged Passwords on <CUSTOMER_SPP_IPV4> address.，代表叢集連結已建立；尚須完成權利、連線原則與實際 RDP／SSH 申請驗收<br>
  ![GITHUB](/images/sppsps/12.png "SPP 使用介面")<br>
## 整合前檢查

確認 SPS 到 SPP 的 TCP 443，以及全部 SPP 與 SPS 節點間雙向 TCP 8649。SPS 節點彼此的 UDP 500／4500 屬 SPS 叢集通訊，不能誤列為 SPP 與 SPS 間流向。確認 DNS、時間與憑證名稱符合實際連線位址。

[官方 CORS 說明](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/46)、[官方 OAuth 建議](https://support.oneidentity.com/pt-br/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/47)、[官方整合限制與連接埠](https://support.oneidentity.com/zh-cn/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/administration-guide/120)。
