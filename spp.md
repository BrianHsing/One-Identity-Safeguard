# Privileged Passwords 密碼模組匯入 <br>

> 下列 Hyper-V 截圖為 SPP 7.0.0.18433 舊示範；8.0 LTS 部署要求另依官方文件說明，不代表 9.0 已重新安裝驗收。

## 使用 VMware 匯入

以下依 SPP 8.0 LTS 官方文件整理，尚無本專案的 VMware 實作截圖。從官方支援入口取得對應 OVA，使用 VMware 部署 OVF 範本流程選取 OVA、資料存放區與核准的網路。完成匯入後先檢查資源及網卡對應，依官方指示移除 USB 控制器，再開機進行初始化。不得以一般 VM 複製或快照作為 SPP 備份還原方式。

## 使用 Hyper-V 匯入官方 VM 套件

- 點選 Hyper-V 管理員匯入虛擬機器<br>
  ![GITHUB](/images/spp/1.png "匯入虛擬機器")<br>
- 點選下一步<br>
  ![GITHUB](/images/spp/2.png "下一步")<br>
- 選擇官方 Hyper-V ZIP 完整解壓縮後、含 VM 組態的資料夾<br>
  ![GITHUB](/images/spp/3.png "選擇官方 Hyper-V ZIP 完整解壓縮後、含 VM 組態的資料夾")<br>
- 確認可以讀取到虛擬機器後，點選下一步<br>
  ![GITHUB](/images/spp/4.png "確認可以讀取到虛擬機器後")<br>
- 選擇匯入類型爲複製虛擬機器(建立新的唯一識別碼)<br>
  ![GITHUB](/images/spp/5.png "選擇匯入類型爲複製虛擬機器")<br>
- 選擇目的地，指定虛擬機器相關資料要存放的資料夾<br>
  ![GITHUB](/images/spp/6.png "選擇目的地")<br>
- 選擇磁碟要存放的資料夾<br>
  ![GITHUB](/images/spp/7.png "選擇磁碟要存放的資料夾")<br>
- 處理匯入精靈的虛擬交換器不存在訊息，選擇核准的交換器；本圖不能辨識此網卡就是 X0<br>
  ![GITHUB](/images/spp/8.png "擇 X0 實際使用的網路介面")<br>
- 處理另一張網卡的交換器對應；不能只依精靈出現順序判斷 MGMT。匯入後以 MAC 位址核對 X0 與 MGMT，依網路設計隔離<br>
  ![GITHUB](/images/spp/9.png "選擇 MGMT 的網路介面")<br>
- 檢查摘要，確認選擇無誤後，點選完成<br>
  ![GITHUB](/images/spp/10.png "檢查摘要")<br>
- 確認虛擬機器完成建立<br>
  ![GITHUB](/images/spp/11.png "確認虛擬機器完成建立")<br>
- 變更虛擬機器名稱為 SPP-Demo<br>
  ![GITHUB](/images/spp/12.png "更虛擬機器名稱為 SPP-Demo")<br>


繼續[使用 Console 初始 SPP 設定](/spp_init.md)<br>
部署前確認 SPP 8.0 LTS 至少 4 vCPU、10 GB RAM、500 GB 磁碟。匯入完成只代表 VM 建立，仍需初始化、授權與功能驗收。[官方部署與初始化說明](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/4)。
