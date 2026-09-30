# Privileged Sessions 側錄模組安裝

> 以下依 SPS 8.0 LTS 說明。舊圖含記憶體與磁碟配置錯誤，已在相鄰步驟標示；保留作辨識用途，尚待補拍修正後的建機畫面。[官方 Hyper-V 指南](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/installation-guide/5)。

## 使用 VMware 建立

以下為 SPS 8.0 LTS 官方程序摘要，尚無 VMware 實作截圖。新增 Linux／Ubuntu 64-bit VM，配置至少 8 GiB 記憶體，磁碟使用固定配置而非隨需擴充。30 GiB 僅為評估下限，正式容量需按同時連線、側錄量與保留天數估算。掛載官方 SPS ISO，以安裝程式完成安裝，再進行 Console 與 Welcome Wizard 設定。[官方 VMware 指南](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-sessions/8.0%20lts/installation-guide/4)。

## 使用 Hyper-V 建立

- 在 Hyper-V 新增虛擬機器<br>
  ![GITHUB](/images/sps/1.png "新增虛擬機器")<br>
- 下一步，自訂組態建立虛擬機器<br>
  ![GITHUB](/images/sps/2.png "自訂組態建立虛擬機器")<br>
- 新增虛擬機器名稱 SPS-Demo，完成後點選下一步<br>
  ![GITHUB](/images/sps/3.png "新增虛擬機器名稱")<br>
- 選擇第一代虛擬機器，完成後點選下一步<br>
  ![GITHUB](/images/sps/4.png "選擇第一代虛擬機器")<br>
- 指派記憶體至少 8,192 MB；本專案容量規劃範例為 32,768 MB，並且將為此虛擬機器使用動態記憶體取消勾選，完成後點選下一步<br>
  **舊圖顯示 4,096 MB，低於 8.0 LTS 最低需求，不可照圖填入。**

  ![GITHUB](/images/sps/5.png "指派記憶體")<br>
- 設定預設使用的網路介面，完成後點選下一步<br>
  ![GITHUB](/images/sps/6.png "指派記憶體")<br>
- 另建固定大小虛擬硬碟並配置給 SPS。30 GiB 僅供評估；正式容量另行估算。下圖為動態擴充 100 GB 的舊示範，不符合本篇固定大小要求，不能照圖完成建置<br>
  ![GITHUB](/images/sps/7.png "虛擬硬碟")<br>
- 將 ISO 檔掛載，完成後點選下一步<br>
  ![GITHUB](/images/sps/8.png "ISO 檔掛載")<br>
- 檢查摘要中的記憶體與磁碟類型符合上述要求，再點選完成。下圖仍是 4 GB／動態擴充的舊摘要，不是合格配置<br>
  ![GITHUB](/images/sps/9.png "確認設定無誤")<br>
- 本示範將虛擬處理器改為 4；正式規格需依負載估算。圖中的 4 GB 記憶體仍須修正；儲存設定不等於產品安裝與驗收完成<br>
  ![GITHUB](/images/sps/10.png "虛擬處理器更改")<br>

繼續[使用 Console 初始 SPS 設定](/sps_init.md)<br>