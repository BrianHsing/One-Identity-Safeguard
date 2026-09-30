# SPP 資產服務帳戶設定

## 目的

指定 SPP 連到資產檢查、變更密碼時使用的驗證身分。本篇的服務帳戶是 SPP 的資產連線憑證，不等同於 Windows 服務的 Log On As 帳戶。

## 適用範圍

以下是 SPP 8.0 LTS 的 Windows／Linux 資產設定方式。Windows 服務與排程工作的相依密碼更新須另行盤點，不能只完成本篇就啟用輪替。

## 前置條件

具備 Asset Administrator 權限。目標端已建立專用管理帳戶，授權範圍符合所選平台的密碼管理需求；Linux 若使用 sudo 或 su，須先核對該平台支援的提權方式。請勿直接以整個網域的高權限帳戶作為共用服務帳戶。

## 操作步驟

1. 在 `Asset Management > Assets` 選取單一測試資產，開啟連線設定，記錄原本驗證類型與帳戶名稱，不記錄密碼。
2. 核對 Platform 與 Network Address。將 Authentication Type 由 None 改成符合平台的 Password、SSH Key 或 Directory Account。
3. Password 填入專用 Service Account Name 與目前密碼；Directory Account 選擇已納管的目錄帳戶；SSH Key 使用已核准的金鑰與所需 passphrase。
4. Linux 資產的主機金鑰須透過主控台或可信管道核對，不能只接受網路首次取得的指紋。
5. 儲存並執行資產連線測試，再對一個非正式環境帳戶執行 Check Password。
6. 連線與檢查均成功後，才按[變更密碼程序](spp-password-change.md)測試一次輪替。

## 注意事項

SPP 官方說明：刪除服務帳戶會使資產驗證類型回到 None，停用該資產帳戶的自動密碼／SSH 金鑰管理。因此移除服務帳戶前，須確認替代憑證與輪替排程。

本專案建議保留一條經核准的緊急維運途徑。測試失敗時恢復原連線設定並核對目標端密碼，不連續觸發變更。

## 相關文件

- [官方：SPP 8.0 LTS，資產驗證與服務帳戶](https://support.oneidentity.com/technical-documents/one-identity-safeguard-for-privileged-passwords/8.0%20lts/administration-guide/59)
- [新增資產](../../spp_asset.md)
