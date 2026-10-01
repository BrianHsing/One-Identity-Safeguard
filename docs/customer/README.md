# 客戶交付文件

[SPP 整合 Microsoft Entra ID 操作指引](SPP整合Microsoft%20Entra%20ID操作指引.docx) 由 [SOP](../sop/spp-entra-id.md) 產生，版本 1.0，日期 2026-10-01。六張截圖以使用者提供的實際畫面為主，另有 Azure Portal 唯讀補拍；已依使用者要求以程式遮蔽個資與環境識別資訊。

文件為部署與驗收指引，不是客戶已完成驗收的報告。修改 SOP 後，使用具 python-docx 的 Python 環境重建整份，勿手改 Word 二進位檔：

```powershell
python tools/build_entra_sop.py
```

建置程式自動排除內部文章比較，保留客戶需要的操作內容、官方來源與流程來源歸屬。輸出採 A4，施工欄位表獨立成頁。

本次以 Microsoft Word 原生 PDF 匯出後逐頁檢查；內部 PDF 與頁面影像不隨客戶版交付。專案沒有保存未遮蔽的原始截圖、SAML XML 或權杖。
