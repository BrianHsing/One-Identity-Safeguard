# One Identity Safeguard
One Identity 致力於提供帳號解決方案，在行業超過20年，全球有5000家以上的企業採用。One Identity 解決方案涵蓋 Identity Governance Administrator ( IGA ) 身分治理與管理、Privileged Access Management ( PAM ) 特權存取管理、Access Management ( AM ) 存取管理、2FA 雙因素驗證。<br>

One Identity Safeguard 是一項整合方案，結合一個安全強固設計的密碼保險箱、連線管理、以及具備威脅偵測與分析能力的監控方案。它能夠安全的儲存、管理、記錄和分析特權存取。<br>

本篇主要會專注於 Privileged Access Management ( PAM ) 特權存取管理，提供 One Identity Safeguard for Privileged Passwords 與 One Identity Safeguard for Privileged Sessions 的安裝步驟。<br>

## 架構說明

One Identity Safeguard for Privileged Passwords 簡稱為 SPP，One Identity Safeguard for Privileged Sessions 簡稱 SPS，One Identity Safeguard for privileged analytics 簡稱 SPA，SPA 會在 SPS 上的啟用，為了方便撰寫，會用簡稱代表。<br>

在部署環境中無論是 VMware 或是 Hyper-V，亦或是公有雲 Azure、AWS，都可以將 Safeguard 部署在您的基礎架構中。在地端虛擬化環境中 SPP 會是以 Virtual Appliance 的方式部署，符合 FIPS-140-2，分別會提供 OVA 與 VHD 匯入。SPS 提供 ISO 檔，您需要將虛擬機器先建立起來，規格給予 4 vCPU、32 GB RAM、500 GB - 4 TB Disk，作業系統類型需要選擇 Ubuntu 64 bit。建議您可以額外準備一個儲存空間，無論是 Windows FileShare 或是 NAS，用於存放SPP 與 SPS 的備份檔、錄影檔，定期的封存錄影檔，可以讓您不需要給予 SPS 太大的儲存空間。在身分驗證的選擇上，您可以使用 SPP Local 帳號或是整合現有的 AD、LDAP 等。當然如果您想要整合 2FA 驗證也是沒問題的，常見的像是 One Identity Defender、Azure MFA、全景、偉康等都能支援，以廣義的來說無論是透過 Redius 或是 SAML 都可以跟 Safeguard 整合。<br>

完成部署後，使用者透過 SPP 提供的網頁服務申請連線，經由指定人員核准後，即可透過 SPS 登入到需要連線的伺服器，所有的過程都會被記錄下來，也可有效的阻隔使用者對伺服器的直接連線。

![GITHUB](/images/architecture.png "architecture")<br>

## 前置作業

- One Identity 下載連結<br>
  https://1drv.ms/f/s!AvZb8cMf7gfXhOhH1WXkYWzGFQBFUg<br>

- 系統導入所需要準備的資源如以下表格。<br>
  
  |虛擬機器|角色說明|規格|數量|備註|
  |----|----|----|----|----|
  |SPP|密碼模組|vCPU:4 core <br> RAM: 10 GB <br> Disk: 100 GB |1|提供OVA或是VHD|
  |SPS|側錄模組|vCPU:4 core <br> RAM: 32 GB <br> Disk: 100 GB |1|提供ISO|
  |Defender|2FA驗證|vCPU:4 core <br> RAM: 16 GB <br> Disk: 100 GB |1|需要準備 Windows Server，提供安裝檔<br> 有需要再準備|
  |RDS|遠端應用程式發佈主機|vCPU:4 core <br> RAM: 16 GB <br> Disk: 100 GB |1|需要準備 Windows Server <br> 有需要再準備|
- 防火牆開通資訊。<br>
  - SPP 到伺服器(納管伺服器建置可整個網段開通)。<br>
  
  |目標角色|協定|開Port|備註|
  |----|----|----|----|
  |AD(DC)|TCP|135、389、445、636、3268、49152-65535|整合AD和納管AD用|
  |Windows Server|TCP|135、445、49152~65535|納管用|
  |DNS|TCP/UDP|53|名稱查詢|
  |NTP|TCP|123|時間校時|
  |Mail Realy|TCP|25|發通知信|
  |Redhat|TCP|22|納管用|
  |KMS|TCP|1688|作業系統授權認證|
  |AIX|TCP|22|納管用|
  |Defender|TCP|1812|驗證用|

  - SPS 到伺服器(納管伺服器建置可整個網段開通)。<br>
  
  |目標角色|協定|開Port|備註|
  |----|----|----|----|
  |Windows Server|TCP|3389|連線代登用|
  |Linux|TCP|22|連線代登用|
  |AIX|TCP/UDP|22|連線代登用|
  |DNS|TCP/UDP|53|名稱查詢|
  |NTP|TCP|25|發通知信|
  |Mail Realy|TCP|22|發通知信|

  - RDS 到伺服器(納管伺服器建置可整個網段開通)。<br>
  
  |目標角色|協定|開Port|備註|
  |----|----|----|----|
  |AD|TCP|88、135、139、389、445、49152~65535|加入AD用|
  |DNS|TCP/UDP|53|連線代豋用|
  |NTP|UDP|123|連線代豋用|
  |根據AP協定的Port而定義|TCP|依據實際Port定義|AP主機代登入用|

  - Defender 到伺服器(納管伺服器建置可整個網段開通)。<br>
  
  |目標角色|協定|開Port|備註|
  |----|----|----|----|
  |AD|TCP|389、636、3268|加入AD用|

- 客戶端 ----> 特權系統。<br>
  - 管理者<br>
  
  |目標角色|協定|開Port|備註|
  |----|----|----|----|
  |SPP|TCP|443|管理和申請登入用|
  |SPS|TCP|443、22、3389|代豋連線用|
  |備份主機|TCP|3389|管理用|
  |RDS|TCP|3389|管理用|

  - 一般使用者<br>
  
  |目標角色|協定|開Port|備註|
  |----|----|----|----|
  |SPP|TCP|443|申請登入用|
  |SPS|TCP|443、22、3389|代豋連線用|

## Safeguard 部署
- SPP 部署步驟
  - 確認擁有 SPP 的匯入檔<br>
    - Hyper-V 為 Safeguard.vhdx<br>
    - VMware 爲 Safeguard-vmware-prod-x.x.x.x.ova<br>
  - [Privileged Passwords 密碼模組匯入](/spp.md)<br>
  - [使用 Console 初始 SPP 設定](/spp_init.md)<br>
  - [使用瀏覽器登入 SPP 進行初始設定](/spp_web.md)<br>
- SPS 部署步驟
  - 建立 vCPU:4 core/RAM: 32 GB/Disk: 100 GB 的虛擬機器<br>
  - 掛載 SPS ISO 檔，此檔案可以 https://1drv.ms/f/s!AvZb8cMf7gfXhOhH1WXkYWzGFQBFUg 下載，路徑為 One Identity Safeguard > SPS > 8<br>
  - [Privileged Sessions 側錄模組安裝](/sps.md)<br>
  - [使用 Console 初始 SPS 設定](/sps_init.md)<br>
  - [使用瀏覽器登入 SPS 初始設定](/sps_web.md)<br>
- [SPS 側錄模組整合 SPP 密碼模組](/sppsps.md)<br>

## SPP 管理者設定

將環境設置好之後，就會需要將我們現有環境納管到特權帳號管理系統中。此節範例，預計將兩台機器納管，可以變更所指定的特權帳號密碼、指定使用者存取。<br>
在這小節，會建立的事情如下：<br>
1.建立額外管理者`sgadmin`用於管理特權帳號、設定組態，作為管理者的角色<br>
2.建立一般使用者`u01`用於登入特權平台、申請存取機器，作為內部使用者或外部廠商的角色<br>
3.建立一般使用者`a01`用於登入特權平台、核准存取行為，作為內部承辦或機器管理者的角色<br>
4.納管機器 Windows 和 Linux 各一台<br>
  - Windows : 10.16.10.151<br>
    - 用於變更密碼:(特權帳號: Administrator | 密碼: 1qaz@WSX)<br>
    - 用於登入:(特權帳號: LoginUser | 密碼: 1qaz@WSX)
  - Linux : 10.16.10.156<br>
    - 用於變更密碼:(特權帳號: Root | 密碼: 1qaz@WSX)<br>
    - 用於登入:(特權帳號: loginuser | 密碼: 1qaz@WSX)<br>

5.將 Windows 和 Linux 這兩台機器可以讓`u01`申請存取 RDP 與 SSH 連線，並且要通過`a01`核准才能連線<br>
- [建立管理者與一般使用者帳號](/spp_user.md)<br>
- [新增資產](/spp_asset.md)<br>
- [新增帳戶](/spp_account.md)<br>
- [新增權利]()<br>

## 使用者操作流程 Coming Soon
- [Windows 登入](/sguser.md)<br>
- [Linux 登入](/sguser.md)<br>

## SPP 管理者進階設定 Coming Soon (option)
- [新增服務帳戶]()<br>
- [資產變更密碼設定]()<br>
- [密碼原則設定]()<br>
- [備份]()<br>
- [Active Directory 整合]()<br>
- [Microsoft Entra ID 整合]()<br>

## SPS 管理者進階設定 Coming Soon (option)
- [OCR 設定與套用]()<br>
- [備份與封存原則]()<br>
- [稽核資料清理原則]()<br>
- [內容原則]()<br>

## 整合遠端應用程式發佈架構 Coming Soon

## 整合 One Identity Defender 架構 Coming Soon

## 其他電腦本機端安裝說明 Coming Soon <br>
- [Safeguard SCALUS 安裝](/scalus.md)<br>
- [Safeguard Desktop Player安裝](/player.md)<br>

