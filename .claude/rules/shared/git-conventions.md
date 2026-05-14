---
applies_to:
  - "**"
priority: medium
category: coding-style
---

# Git Conventions

## 適用範囲

すべての PR。コミットメッセージ、PR タイトル、変更粒度に関する規約。

## ルール

### MUST

- PR タイトルは Conventional Commits 形式 (`<type>: <subject>`) で書く
  - type: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `style`
- 1 PR = 1 つの論理的変更。**無関係な変更を混ぜない**
- フォーマット変更とロジック変更を同じコミットに混ぜない

### SHOULD

- PR の説明欄に「何を」「なぜ」を書く（「どう」は diff を見れば分かる）
- 関連 issue へのリンクを付ける（`Fixes #123` など）
- スクリーンショットや動作確認結果を添える（UI 変更の場合）

### NIT

- コミットメッセージの本文（body）に context を書くと将来の調査が楽になる

## ❌ 悪い例

PR タイトル:
```
update
```

PR で 1 つの変更に：
- バグ修正
- 無関係なリファクタ
- prettier の一括フォーマット

が全部混じっている。

## ✅ 良い例

PR タイトル:
```
fix: ユーザー登録時のメール重複チェックが動かない問題を修正
```

PR 説明:
```markdown
## 何を
`/api/users` の重複チェック時に email を小文字化していなかったため、
大文字小文字違いで重複登録できてしまっていた。`strings.ToLower` で
正規化してから比較するように修正。

## なぜ
ユーザー報告 #456。重複アカウントの混乱を防ぐため。

## 確認
- 既存テストパス
- 新規テスト追加: `TestUserRegister_CaseInsensitiveEmail`
```

## 根拠

- 1 PR の粒度を小さく保つことでレビュー品質が上がり、リバートも容易になる
- Conventional Commits により changelog の自動生成が可能
- 「なぜ」を書くことで半年後の調査コストが激減する

## 関連ルール

- なし
