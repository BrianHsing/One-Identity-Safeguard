---
description: 依指定主題產生 One Identity Safeguard SOP 文件，並自動 git add、commit、push
---

請依照以下規範，為「$ARGUMENTS」撰寫一份 SOP 文件。

## 規範

- 存放路徑：`docs/sop/`
- 檔名：以英文小寫加連字號命名（例：`spp-account-management.md`）
- 語言：繁體中文
- 格式：Markdown

## 文件結構

產生的 SOP 必須包含以下章節：

```
# <SOP 標題>

## 目的
## 適用範圍
## 前置條件
## 操作步驟
## 注意事項
## 相關文件
```

## 完成後

文件寫入後，依序執行：

```bash
git add docs/sop/
git commit -m "docs: 新增 SOP — <文件標題>"
git push
```
