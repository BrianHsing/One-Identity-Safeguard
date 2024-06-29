# One Identity Safeguard <br>
One Identity 致力於提供帳號解決方案，在行業超過20年，全球有5000家以上的企業採用。One Identity 解決方案涵蓋 Identity Governance Administrator ( IGA ) 身分治理與管理、Privileged Access Management ( PAM ) 特權存取管理、Access Management ( AM ) 存取管理、2FA 雙因素驗證。<br>

One Identity Safeguard 是一項整合方案，結合一個安全強固設計的密碼保險箱、連線管理、以及具備威脅偵測與分析能力的監控方案。它能夠安全的儲存、管理、記錄和分析特權存取。<br>

本篇主要會專注於 Privileged Access Management ( PAM ) 特權存取管理，提供 One Identity Safeguard for Privileged Passwords 與 One Identity Safeguard for Privileged Sessions 的安裝步驟。<br>

## 架構說明 <br>

One Identity Safeguard for Privileged Passwords 簡稱為 SPP，One Identity Safeguard for Privileged Sessions 簡稱 SPS，One Identity Safeguard for privileged analytics 簡稱 SPA，SPA 會在 SPS 上的啟用，為了方便撰寫，會用簡稱代表。<br>

在部署環境中無論是 VMware 或是 Hyper-V，亦或是公有雲 Azure、AWS，都可以將 Safeguard 部署在您的基礎架構中。在地端虛擬化環境中 SPP 會是以 Virtual Appliance 的方式部署，符合 FIPS-140-2，分別會提供 OVA 與 VHD 匯入。SPS 提供 ISO 檔，您需要將虛擬機器先建立起來，規格給予 4 vCPU、32 GB RAM、500 GB - 4 TB Disk，作業系統類型需要選擇 Ubuntu 64 bit。建議您可以額外準備一個儲存空間，無論是 Windows FileShare 或是 NAS，用於存放SPP 與 SPS 的備份檔、錄影檔，定期的封存錄影檔，可以讓您不需要給予 SPS 太大的儲存空間。在身分驗證的選擇上，您可以使用 SPP Local 帳號或是整合現有的 AD、LDAP 等。當然如果您想要整合 2FA 驗證也是沒問題的，常見的像是 One Identity Defender、Azure MFA、全景、偉康等都能支援，以廣義的來說無論是透過 Redius 或是 SAML 都可以跟 Safeguard 整合。<br>

完成部署後，使用者透過 SPP 提供的網頁服務申請連線，經由指定人員核准後，即可透過 SPS 登入到需要連線的伺服器，所有的過程都會被記錄下來，也可有效的阻隔使用者對伺服器的直接連線。

![GITHUB](/images/architecture.png "architecture")<br>

## 前置作業 <br>

## 部署流程 <br>

## 其他產品安裝 <br>



