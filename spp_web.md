# 使用瀏覽器登入 SPP 進行初始設定<br>

> 本篇含 SPP 7.0 至 8.0 的歷史升級畫面，不是目前 9.0 實作紀錄。舊 IP 10.16.10.90 不同於本次觀察環境 10.16.10.110。

## 授權指派

- 開啟瀏覽器輸入 https://10.16.10.90 開啟 SPP 使用介面，使用已完成初始化、具有適當管理角色的帳戶登入<br>
  ![GITHUB](/images/spp/spp_web/1.png "SPP 使用介面")<br>
- 收到 Safeguard is not licensed 的警示通知，點選確定<br>
  ![GITHUB](/images/spp/spp_web/2.png "Safeguard is not licensed")<br>
- 使用 One Identity 核發給本環境的 SPP 授權檔；由授權窗口確認 entitlement 與適用版本<br>

- 若無法套用授權，先保留錯誤訊息並核對授權產品、期限與適用版本，必要時聯繫原廠；不要直接以升級處理所有授權錯誤<br>
- 將授權從裝置上傳，過程中會需要你接受軟體交易合約<br>
  ![GITHUB](/images/spp/spp_web/4.png "授權裝置上傳")<br>
- 完成後檢查產品授權狀態、期限與作業系統授權。下圖為到期日 2025-03-09 的舊試用授權，且有作業系統未授權警告，不是有效授權驗收證據<br>
  ![GITHUB](/images/spp/spp_web/5.png "授權狀態")<br>

## 修補程式更新

- 在裝置管理功能類別展開，點選裝置，找到修補程式更新<br>
  ![GITHUB](/images/spp/spp_web/6.png "修補程式更新")<br>
- 從 [One Identity 官方支援入口](https://support.oneidentity.com/) 下載符合目標版本及升級路徑的修補檔；先閱讀版本資訊、完成備份並安排維護時段<br>

- 上傳修補程式更新檔，上傳後，點選立即安裝<br>
  ![GITHUB](/images/spp/spp_web/8.png "sgp")<br>
- 跳出安裝更新的視窗，在方塊內輸入安裝之後，點選安裝的按鈕會立即開始更新作業<br>
  ![GITHUB](/images/spp/spp_web/9.png "安裝更新")<br>
  ![GITHUB](/images/spp/spp_web/10.png "安裝更新")<br>
- 等待維護程序結束再點選繼續；更新中不要重新整理或離開頁面。是否重新啟動依該版本指示，不保證全程不中斷。更新後核對版本、節點健康與申請／連線流程<br>
  ![GITHUB](/images/spp/spp_web/11.png "安裝更新")<br>

[官方修補程序](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/26)；[官方授權說明](https://support.oneidentity.com/technical-documents/one-identity-safeguard/8.0%20lts/administration-guide/22)。
