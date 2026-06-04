# skills-plugin

iy06の Claude Code スキルを管理する GitHub プラグインリポジトリです。

## インストール

### マーケットプレイスを追加してインストール

Claude Code の `/plugin` コマンドで追加できます：

```
/plugin marketplace add github:iy06/skills-plugin
/plugin install skills-plugin@iy06-skills
```

または CLI から：

```bash
claude plugin install skills-plugin@iy06-skills
```

## スキル一覧

| スキル名 | 説明 |
|---|---|
| `session-start-hook` | Claude Code on the web 向けのセッション開始フックを作成する |
| `code-review` | セキュリティ・アーキテクチャ・パフォーマンス・可読性の観点でコードをレビューする |
| `grill-me` | ユーザーの実装要望を、徹底的な質問と推奨回答の提示を通じて具体化し、実装前に設計書として合意を取る |
| `grill-you` | 既存コード・機能・概念について調査と解説を行い、追加質問に応じて深掘りすることで理解を深める |
| `grill-product` | アプリの要件を定義し、現在の機能と将来欲しい機能を整理した要件定義書を作成する |
| `gui-event-audit` | GUI のイベントを網羅的に列挙し、各イベントの実効を層をまたいで末端まで追跡して、押しても効かない・キャンセルできない・イベント競合などの矛盾を静的解析で発見する |

## 構造

```
skills-plugin/
├── .claude-plugin/
│   ├── plugin.json        # プラグインマニフェスト
│   └── marketplace.json   # マーケットプレイスカタログ
└── skills/
    └── session-start-hook/
        └── SKILL.md
```

## スキルの追加

1. `skills/<skill-name>/SKILL.md` を作成する
2. フロントマターに `description` を記載する
3. コミット・プッシュする

### SKILL.md の形式

```markdown
---
description: スキルの説明。Claudeがいつ使うかを記述する。
---

# スキルのタイトル

スキルの内容をここに書く。
```


## 更新

```
/plugin marketplace update iy06-skills
/plugin update skills-plugin@iy06-skills
```
