# コメント投稿の使い分けとフォーマット

`pr-review` がコメントを投稿する段階で読む。インライン / サマリーの 2 系統。

## インラインコメント（特定行への指摘）

**ツール**: `mcp__github_inline_comment__create_inline_comment`

**使う場面**:

- 具体的なコード行に対する指摘
- 修正提案（suggestion ブロックで具体的な置換を提案できる）

**フォーマット**:

````markdown
[MUST] `.claude/rules/backend/security.md` の「ユーザー入力は必ず検証する」に違反。

`req.Body` のフィールド `email` がバリデーションされていません。フォーマット検証と
長さ制限を追加してください。

```go
// 修正例
if err := validateEmail(req.Email); err != nil {
    return badRequest(w, err)
}
```
````

## サマリーコメント（PR 全体への top-level コメント）

**ツール**: `gh pr comment <PR_NUMBER> --body "..."`

**使う場面**:

- レビュー結果の全体サマリー
- レビュー対象とした観点・読んだルールの記録
- 大局的な指摘（設計レベルの懸念）

**フォーマット**:

```markdown
## Claude Review

<!-- 結果サマリー -->
- [MUST] 2 件
- [SHOULD] 3 件
- [NIT] 1 件

<!-- レビュー範囲の透明性 -->
### 確認したルール
- `.claude/rules/shared/git-conventions.md`
- `.claude/rules/backend/security.md`
- ...

### 確認したファイル
`apps/api/handlers/user.go`, `apps/api/repository/user.go`, ...

### 主な懸念
（あれば、設計レベルの大局的な指摘をここに）

---

このレビューは Claude による自動レビューです。誤検知・見落としを見つけたら、
PR テンプレの「Claude レビューへのフィードバック」欄に記録してください。
ルール更新のトリガーになります。
```

## 指摘ゼロの場合

沈黙は禁止。問題が見つからなくても、確認範囲を明示したサマリーを残す。

```markdown
## Claude Review

✅ レビューしたルールに違反する箇所は見つかりませんでした。

### 確認したルール
- `.claude/rules/shared/git-conventions.md`
- `.claude/rules/backend/coding-style.md`
- `.claude/rules/backend/security.md`

### 確認したファイル数
12 files, +234 / -56 lines
```

## `.claude/rules/` が存在しない場合

```markdown
## Claude Review — セットアップ未完了

このリポジトリには `.claude/rules/` が存在しないため、プロジェクト固有のルールに
基づくレビューができません。

pr-review skill の examples/rules/ をコピーしてセットアップしてください。
```

そのうえで一般的な観点での簡易レビューに切り替える（セキュリティ・明らかなバグのみ）。
ルールに基づかない指摘には `[SUGGEST]` を付け、`[MUST]` は使わない。
