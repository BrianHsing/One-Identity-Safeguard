# 整份文件審查紀錄

審查日期：2026-09-30。結論：已修正已確認的圖文矛盾與部署風險，可供內部導讀與現場操作準備；尚不能作為全部功能均已實測的客戶交付完成版。

## 審查範圍與方法

審查原有 33 份內容文件（根目錄 14 份、SOP 19 份），另讀取 CLAUDE.md 工作規範。逐篇讀取文字，檢查本機連結及圖片引用。檢視 87 張不同的舊版引用圖片、22 張 SPP／SPS 實機補圖及 4 張 SCALUS 圖片，共 113 張；舊圖以聯絡表檢視，必要時對照原圖。此數量是修正前的引用範圍，移除兩張私人下載來源圖後，不能以原數量宣稱目前仍全部嵌入文件。

這是內容、圖文與證據界線審查，不是重新部署或全功能驗收；本次未變更 SPP／SPS 設定，也未宣稱所有產品行為已用 9.0 官方文件核實。

## 主要修正

| 問題 | 修正及仍存在的界線 |
|---|---|
| SPP 資源表寫 100 GB | 改為官方 8.0 LTS 的 500 GB 最低磁碟需求；9.0 部署仍須查當版需求 |
| SPS 文字 32 GB，圖為 4 GB；圖中磁碟為動態擴充 | 標示舊圖不合格，正文改為至少 8 GiB 與固定大小磁碟；尚缺修正後建機截圖 |
| SPP 初始化實為 7.0，其他部署圖混有 8.0 | 各篇標出歷史版本，不再視為目前 9.0 安裝證據 |
| VMware 留白 | 補官方程序摘要，明示尚無 VMware 實作截圖 |
| SPP 私人下載來源、更新不用重開機、授權失敗即升級 | 改官方取得管道、備份及維護時段、按目標版本完成更新與健康檢查 |
| SPS 圖仍在 Applying configuration，原文稱完成 | 改為套用中，要求等待並重新登入確認 |
| CORS 全開與 OAuth 額外授予被當成必要步驟 | 改用核准主機與預設 PKCE，舊圖明示不宜沿用 |
| 局部截圖被拿來支撐畫面外欄位或功能成功 | 補入圖片可見範圍及未實測界線 |
| 內容原則負向測試與正向測試混在同一畫面 | 改為獨立工作階段，避免殘留字串造成誤判 |

## 逐篇審查範圍

| 文件 | 審查結果 |
|---|---|
| [README.md](../README.md) | 修正架構、資源、來源與主要網路流向；改作版本分流入口。 |
| [spp.md](../spp.md) | 修正完整 VM 套件匯入與網卡辨識；舊圖 7.0、VMware 未實作。 |
| [sps.md](../sps.md) | 明示 RAM／動態磁碟錯誤舊圖；需補正確建機圖。 |
| [spp_init.md](../spp_init.md) | 修正 OS 授權與 NTP 說明；初始化不等於功能驗收。 |
| [sps_init.md](../sps_init.md) | 限定首次 Wizard 前的 shell 網路設定，補磁碟清除提醒。 |
| [spp_web.md](../spp_web.md) | 修正授權與更新流程；到期試用圖不是成功證據。 |
| [sps_web.md](../sps_web.md) | 修正套用中與完成的區別；舊圖含識別資料。 |
| [sppsps.md](../sppsps.md) | 修正 CORS、OAuth 與連結完成範圍；補連接埠與不可解除連結界線。 |
| [spp_asset.md](../spp_asset.md) | 標示舊版與主機金鑰驗證要求；未證明自動密碼管理可用。 |
| [spp_user.md](../spp_user.md) | 區分建立帳戶、授權與核准角色；既有勾選不等於建議值。 |
| [spp_account.md](../spp_account.md) | 修正索引頁版本說明；新增帳戶結果未驗收。 |
| [sgadmin.md](../sgadmin.md) | 管理角色索引可用；各功能成功仍依分篇驗收。 |
| [scalus.md](../scalus.md) | 操作入口可用；不宣稱完整安裝實測。 |
| [player.md](../player.md) | 操作入口可用；沒有本機安裝與播放證據。 |

19 份 SOP 均已納入文字與引用審查；功能證據詳見[實機截圖與驗證範圍](sop/environment-evidence.md)。

| SOP | 證據判定 |
|---|---|
| [defender-integration](sop/defender-integration.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [desktop-player-install](sop/desktop-player-install.md) | 官方程序參考；缺安裝及播放實機證據。 |
| [environment-evidence](sop/environment-evidence.md) | 證據索引；清楚區分觀察與尚未驗收項目。 |
| [remoteapp-integration](sop/remoteapp-integration.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [scalus-install](sop/scalus-install.md) | 4 張本機設定圖匹配；缺安裝、協定關聯與連線啟動驗收。 |
| [spp-account-management](sop/spp-account-management.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [spp-active-directory](sop/spp-active-directory.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [spp-admin-login](sop/spp-admin-login.md) | 入口與首頁證據；不延伸宣稱其他角色或功能驗收。 |
| [spp-backup](sop/spp-backup.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [spp-entitlements](sop/spp-entitlements.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [spp-entra-id](sop/spp-entra-id.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [spp-password-change](sop/spp-password-change.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [spp-password-policy](sop/spp-password-policy.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [spp-service-account](sop/spp-service-account.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [spp-session-workflow](sop/spp-session-workflow.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [sps-audit-cleanup](sop/sps-audit-cleanup.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [sps-backup-archive](sop/sps-backup-archive.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [sps-content-policy](sop/sps-content-policy.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |
| [sps-ocr](sop/sps-ocr.md) | 實機設定或表單可作導讀；正式變更與結果驗收仍未完成。 |

## 客戶交付前仍須完成

1. 以目標部署版本統一主流程，補拍合格的 SPS 建機、VMware 及初始化完成畫面；舊版圖宜移入歷史附錄。
2. 完成申請、核准、RDP／SSH 登入、歸還、密碼輪替、備份及隔離還原等適用情境，保留預期與實際結果。選用整合須各自完成往返測試。
3. 補 Desktop Player 安裝／回放及 SCALUS 啟動證據；現有設定頁不等於程式使用成功。
4. 舊圖含真實信箱、組織與授權識別資料。對外提供前去識別；本次沒有修改圖片像素，也未清除 Git 歷史中的舊資料，因此不能宣稱已完成對外去識別。
5. 以客戶核准的版本、網段、憑證、授權與保存政策完成專案檢查表及簽核。本文件沒有取代原廠支援矩陣或現場驗收。

## 驗證界線

本機檢查涵蓋 Markdown 連結存在性、19 份 SOP 必要章節及 26 張補拍 JPEG 格式／尺寸。通過結構檢查不能證明連線、備份、OCR、MFA 或刪除政策運作成功。官方依據連結放在修正段落相鄰位置。
