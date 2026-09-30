# 管理者操作

以下依 SPP／SPS 8.0 LTS 規劃。正式環境依職責分派權限，sgadmin 為本專案的示範名稱，不代表每位管理者均需完整系統權限。

|工作|SPP 管理角色或範圍|操作文件|
|---|---|---|
|新增平台使用者|User Administrator|[建立使用者](spp_user.md)|
|資產與帳戶納管|Asset Administrator／分割區委派|[新增帳戶](docs/sop/spp-account-management.md)|
|密碼管理|Asset Administrator／分割區委派|[服務帳戶](docs/sop/spp-service-account.md)、[密碼輪替](docs/sop/spp-password-change.md)|
|申請與簽核原則|Security Policy Administrator|[新增權利](docs/sop/spp-entitlements.md)|
|裝置備份與登入整合|Appliance Administrator；使用者指派由 User Administrator 配合|[備份](docs/sop/spp-backup.md)、[AD](docs/sop/spp-active-directory.md)、[Entra ID](docs/sop/spp-entra-id.md)|

日常檢查應核對備份結果、密碼管理失敗、SPS 儲存使用量、封存與索引佇列，以及即將到期的憑證。異常保留時間、資產、工作編號與遮罩後的訊息，不記錄密碼或 Token。

變更前記錄目前設定與影響範圍，先在單一測試對象驗證；變更後以申請、核准、連線、歸還及回放驗證完整流程。

[回專案目錄](README.md)
