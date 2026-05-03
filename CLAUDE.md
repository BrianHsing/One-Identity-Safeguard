# One Identity Safeguard — Claude 工作指引

## SOP 文件規範

- **存放路徑**：`docs/sop/`
- **文件格式**：Markdown（`.md`）
- **撰寫語言**：繁體中文

## 產生 SOP 後的自動化流程

每次產生或更新 SOP 文件後，依序執行以下 git 操作：

```bash
git add docs/sop/
git commit -m "docs: 新增/更新 SOP — <文件名稱>"
git push
```

> 若同時產生多份文件，將所有異動一併納入同一個 commit。
