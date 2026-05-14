---
# このルールが適用されるファイルパターン（glob）
applies_to:
  - "<例: apps/web/**/*.ts>"
  - "<例: apps/web/**/*.tsx>"

# 重要度: high / medium / low
priority: medium

# レビュー観点: coding-style / architecture / testing / security / performance / a11y
category: coding-style
---

# <ルール名>

## 適用範囲

何を対象に、いつ確認するルールか。1〜3 行で簡潔に。

## ルール

### MUST（マージブロッカー級）

- 必ず守るべきこと 1
- 必ず守るべきこと 2

### SHOULD（強く推奨）

- 推奨事項 1
- 推奨事項 2

### NIT（細かい指摘）

- 任意の改善 1

## ❌ 悪い例

```ts
// このような書き方は禁止
```

## ✅ 良い例

```ts
// 推奨される書き方
```

## 根拠

このルールが必要な理由を書く。例：

- 過去のバグ事例: <PR #123 で発生した N+1 問題>
- セキュリティインシデント: <2024-XX-XX の SQLi 事例>
- ADR: <docs/adr/0042-prepared-statements.md>
- 外部リファレンス: <OWASP Top 10 - Injection>

## 関連ルール

- `.claude/rules/<関連ファイル>.md`
