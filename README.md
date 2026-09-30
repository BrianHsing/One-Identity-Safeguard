# One Identity Safeguard

> SOP 已補入 2026-09-30 的 SPP 9.0.0.2807／SPS 9.0.0 實機截圖與中文欄位說明。原理與部分部署程序仍引用 8.0 LTS 官方文件，已分別標示版本；畫面檢視不等於端到端驗收。請先看[實機截圖與驗證範圍](docs/sop/environment-evidence.md)。根目錄舊部署圖片保留原示範環境。

> 範例 IP 與帳號僅供辨識操作流程。對外提供前須檢查既有圖片中的信箱、姓名、組織、授權資訊與環境識別資料並去識別；不要沿用範例密碼。

One Identity Safeguard for Privileged Passwords（SPP）用於管理特權帳戶、密碼與存取申請；Safeguard for Privileged Sessions（SPS）提供工作階段代理與稽核。本專案包含部署參考、管理程序與實機畫面。

## 架構與版本界線

SPP 處理申請與核准，SPS 依連線及通道原則代理工作階段。是否側錄取決於原則設定；阻止使用者直接連到目標主機，仍須以網路 ACL 與主機權限控管落實。

舊部署圖涵蓋 SPP 7.0／8.0 與 SPS 8.0；本次補拍為 SPP 9.0.0.2807、SPS 9.0.0。不能將整份視為同一版本的安裝紀錄。完整審查結果見[整份文件審查](docs/documentation-review.md)。

![既有架構示意](/images/architecture.png)

此圖保留為歷史架構示意；連接埠以目標版本官方文件為準，尤其 SPS 節點間 UDP 500／4500 不可解讀為 SPP 與 SPS 間通訊。

## 前置作業

安裝映像與修補檔由 [One Identity 官方支援入口](https://support.oneidentity.com/) 取得，授權檔由授權窗口核發。確認目標版本的升級路徑、支援平台與授權條件，再安排安裝。

| 產品與版本 | 部署資源依據 | 容量界線 |
|---|---|---|
| SPP 8.0 LTS | 最少 4 vCPU、10 GB RAM、500 GB 磁碟 | 使用官方 VM 套件；不是一般 Windows VM 自行安裝 |
| SPS 8.0 LTS | 至少 8 GiB RAM；固定大小磁碟 | 30 GiB 僅供評估；32 GiB RAM 是本專案規劃範例，正式資源依連線量、側錄量與保留期間估算 |
| Defender／RDS | 選用整合元件 | 分別確認產品、Windows Server 與 RDS 授權及容量，不沿用示範規格作為最低需求 |

依據：[SPP 8.0 部署要求](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/4)、[SPS 8.0 Hyper-V 要求](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/installation-guide/5)。部署 9.0 時須重新核對 9.0 要求，不能直接以此表簽核。

防火牆應列出確切來源、目的地、方向及用途。以下只涵蓋主要流向，不能代替完整開通單：

| 流向 | 用途與連接埠 |
|---|---|
| 管理者／申請人 → SPP | HTTPS TCP 443 |
| 管理者 → SPS | 管理介面 HTTPS TCP 443 |
| SPS → SPP | 整合 HTTPS TCP 443 |
| 所有 SPP 節點 ↔ 所有 SPS 節點 | TCP 8649，雙向 |
| SPS 節點 ↔ SPS 節點 | 叢集通訊 UDP 500、4500 |
| 使用者 → SPS → 目標主機 | 依 Connection Policy 設定 RDP／SSH 監聽與目的連接埠；預設服務常見 TCP 3389／22，不能忽略自訂值 |
| SPP／SPS → 基礎服務及外部整合 | DNS、NTP、SMTP、AD、備份、RADIUS 等依實際整合逐項查證與開通 |

[官方 SPP／SPS 整合流向](https://support.oneidentity.com/zh-cn/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/administration-guide/120)；[SPP 8.0 連接埠清單](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/157)。

## Safeguard 部署

- SPP 部署步驟
  - 確認擁有 SPP 的匯入檔<br>
    - Hyper-V 使用官方 ZIP 完整解壓縮內容，包含 VM 組態與 VHDX<br>
    - VMware 爲 Safeguard-vmware-prod-x.x.x.x.ova<br>
  - [Privileged Passwords 密碼模組匯入](/spp.md)<br>
  - [使用 Console 初始 SPP 設定](/spp_init.md)<br>
  - [使用瀏覽器登入 SPP 進行初始設定](/spp_web.md)<br>
- SPS 部署步驟
  - 依目標版本與容量規劃建立虛擬機器，磁碟採固定大小<br>
  - 掛載由官方支援入口取得的 SPS ISO<br>
  - [Privileged Sessions 側錄模組安裝](/sps.md)<br>
  - [使用 Console 初始 SPS 設定](/sps_init.md)<br>
  - [使用瀏覽器登入 SPS 初始設定](/sps_web.md)<br>
- [SPS 側錄模組整合 SPP 密碼模組](/sppsps.md)<br>

## SPP 管理者設定

[管理者角色與操作索引](sgadmin.md)｜[管理員登入](docs/sop/spp-admin-login.md)

將環境設置好之後，就會需要將我們現有環境納管到特權帳號管理系統中。此節範例，預計將兩台機器納管，可以變更所指定的特權帳號密碼、指定使用者存取。<br>
在這小節，會建立的事情如下：<br>
1.建立額外管理者`sgadmin`用於管理特權帳號、設定組態，作為管理者的角色<br>
2.建立一般使用者`u01`用於登入特權平台、申請存取機器，作為內部使用者或外部廠商的角色<br>
3.建立一般使用者`a01`用於登入特權平台、核准存取行為，作為內部承辦或機器管理者的角色<br>
4.納管機器 Windows 和 Linux 各一台<br>
  - Windows : 10.16.10.151<br>
    - 用於變更密碼:(特權帳號: Administrator | 密碼: `<CUSTOMER_ACCOUNT_PASSWORD>`)<br>
    - 用於登入:(特權帳號: LoginUser | 密碼: `<CUSTOMER_ACCOUNT_PASSWORD>`)
  - Linux : 10.16.10.156<br>
    - 用於變更密碼:(特權帳號: root | 密碼: `<CUSTOMER_ACCOUNT_PASSWORD>`)<br>
    - 用於登入:(特權帳號: loginuser | 密碼: `<CUSTOMER_ACCOUNT_PASSWORD>`)<br>

5.將 Windows 和 Linux 這兩台機器可以讓`u01`申請存取 RDP 與 SSH 連線，並且要通過`a01`核准才能連線<br>
- [建立管理者與一般使用者帳號](/spp_user.md)<br>
- [新增資產](/spp_asset.md)<br>
- [新增帳戶](/spp_account.md)<br>
- [新增權利](docs/sop/spp-entitlements.md)<br>

## 使用者操作 Demo

[申請、核准、連線與歸還操作](docs/sop/spp-session-workflow.md)。下列影片保留作為既有示範。
- [使用者申請存取](https://www.youtube.com/watch?v=Ousy0D3MnaU)<br>
- [核准存取](https://youtu.be/lsCX_STG74E)<br>
- [RDP 登入](https://youtu.be/R6kUTNejamQ)<br>
- [SSH 登入](https://youtu.be/5afc9vUnVsI)<br>

## SPP 管理者進階設定（選用）

- [新增服務帳戶](docs/sop/spp-service-account.md)<br>
- [資產變更密碼設定](docs/sop/spp-password-change.md)<br>
- [密碼原則設定](docs/sop/spp-password-policy.md)<br>
- [備份](docs/sop/spp-backup.md)<br>
- [Active Directory 整合](docs/sop/spp-active-directory.md)<br>
- [Microsoft Entra ID 整合](docs/sop/spp-entra-id.md)<br>

## SPS 管理者進階設定（選用）

- [OCR 設定與套用](docs/sop/sps-ocr.md)<br>
- [備份與封存原則](docs/sop/sps-backup-archive.md)<br>
- [稽核資料清理原則](docs/sop/sps-audit-cleanup.md)<br>
- [內容原則](docs/sop/sps-content-policy.md)<br>

## 整合遠端應用程式發佈架構

[SPP／SPS RemoteApp 整合流程](docs/sop/remoteapp-integration.md)，包含架構、RDS 授權考量與驗收。

## 整合 One Identity Defender 架構

[SPP 與 Defender 第二因素驗證整合](docs/sop/defender-integration.md)，包含 RADIUS 流向與測試程序。

## 其他電腦本機端安裝說明 <br>

- [Safeguard SCALUS 安裝](/scalus.md)<br>
- [Safeguard Desktop Player安裝](/player.md)<br>

## 知識庫（KB）

[KB 目錄](docs/kb/README.md)收錄既有文件與問題處理指引。

- [SPP 外部 Federation：AADSTS75011](docs/kb/spp-federation-aadsts75011.md)
- [RDP 工作階段重新導向本機磁碟](docs/kb/safeguard-rdp-drive-redirection.md)
