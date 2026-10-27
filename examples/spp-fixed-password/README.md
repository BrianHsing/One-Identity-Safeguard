# SPP 固定密碼流程：PowerShell 7 範例

操作順序、限制與驗收方式請見 [KB-005](../../docs/kb/spp-fixed-password-windows.md)。本套件由使用者提供的 Windows lab 流程整理，公開版修改僅做靜態及合成資料測試，未在實機重新驗證。AIX 客戶成功案例不等同這份 Windows 部署腳本已在 AIX 驗收。

## 檔案與用途

| 檔案 | 用途 |
|---|---|
| config.example.json | 去識別設定範例，複製為 config.json；CUSTOMER 欄位與 ID 0 須替換 |
| Common.ps1 | 設定檢查、SPP 登入、API 與白名單日誌共用函式 |
| SPP-Windows-TARGET_ACCOUNT-FixedPassword_v1.ps1 | 固定值 Runner：核對單帳號群組、設定密碼、ChangePassword、CheckPassword |
| SPP-Windows-TARGET_ACCOUNT-OnCheckin_v1.ps1 | 事件基準、稽核事件去重及逐筆呼叫 Runner |
| Install-DailyTask.ps1 | 建立每日 03:00 Interactive 工作；需使用者保持登入 |
| Install-WindowsTasks.ps1 | 設定部署資料夾 ACL、Password 模式的 Listener／Worker 工作及來源受限防火牆規則 |
| Configure-SPPNotification.ps1 | 預覽或建立 SPP TCP Syslog 通知，實際建立須加 -Apply |
| Receive-SPPCheckin.ps1 | TCP Listener、本機佇列與 Worker 啟動 |
| Receiver.Core.ps1 | 不含網路操作的訊息分框與事件篩選函式 |
| Invoke-CheckinWorker.ps1 | 驗證通知、呼叫事件處理、阻擋失敗與保留佇列 |
| Get-DeploymentStatus.ps1 | 顯示 Listener／Worker 及本機狀態，不包含 Daily |
| Resume-UnsubmittedCheckin.ps1 | 限定尚無密碼工作且無未解決群組寫入的事件復原；預設只檢查 |
| tests/Test-ReceiverCore.ps1 | 合成訊息與工作狀態等待測試；不連線、不讀認證、不安裝或修改主機設定 |

## 部署原則

只在 Windows／PowerShell 7 執行。將套件複製至專用部署目錄，在實際工作執行帳號下建立 spp-credential.xml、fixed-password.xml。DPAPI 限同使用者與同機器；配合 ACL，不代表同身分程序無法解密。實際設定、認證、runtime 與日誌均由 .gitignore 排除，不得強制加入版本控制。

異動入口採整體動作的 SupportsShouldProcess 保護，先 -WhatIf，再以 -Confirm 對單一核准對象實跑。WhatIf 在連線與檔案寫入前返回，無法代替 InspectOnly 的環境查核。Configure／Resume 必須以 -Apply -WhatIf 預覽實際模式；未指定 -Apply 時是連線讀取的預覽。

自動工作使用同一已核准動作，不逐筆彈出確認；安裝工作代表後續事件或排程會觸發真實重設。固定密碼只從受保護檔案讀取；預設不開啟延伸密碼工作日誌。執行紀錄保留階段與工作 ID，不記錄密碼前後值。

未完成的 password-operation.json 會阻擋重跑，即使 SPP 尚未產生工作 ID。不要刪除 runtime、修改成功狀態或重新初始化來解除阻擋。停用／回復與已知限制見 KB。

## 本機無副作用測試

```powershell
pwsh -NoProfile -File .\tests\Test-ReceiverCore.ps1
```

此測試載入 Receiver.Core.ps1 的純函式，並從 Runner 語法樹擷取等待函式，以記憶體中的假 API 回應驗證狀態處理。不要把 Runner、Installer、Worker 或 Listener 當成測試入口；本次未執行這些副作用腳本。
