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

## エージェント一覧

開発フローの各フェーズ (要件 → 設計 → 実装) の成果物をレビューする subagent です。プラグインをインストールすると Task ツールの subagent として利用でき、対応するスキルの出力を受けて品質確認する下流工程として機能します。

| エージェント名 | 説明 | 上流スキル |
|---|---|---|
| `requirements-review` | 要件定義書 / PRD をルーブリックで検証し、設計フェーズに進んで良いか判定する | `grill-product` |
| `design-review` | 設計書 / アーキテクチャを検証し、要件との対応マップを作って実装に進んで良いか判定する | `grill-me` |
| `code-review` | ローカルの作業ブランチ・コミット範囲・ファイル群の実装をレビューする (GitHub PR レビューは `pr-review` スキルが担当) | — |

## 構造

```
skills-plugin/
├── .claude-plugin/
│   ├── plugin.json        # プラグインマニフェスト
│   └── marketplace.json   # マーケットプレイスカタログ
├── agents/                # subagent 定義 (ディレクトリ自動検出)
│   ├── requirements-review.md
│   ├── design-review.md
│   └── code-review.md
└── skills/
    └── session-start-hook/
        └── SKILL.md
```

## スキルの追加

1. `skills/<skill-name>/SKILL.md` を作成する
2. フロントマターに `description` を記載する
3. コミット・プッシュする

## エージェントの追加

1. `agents/<agent-name>.md` を作成する
2. フロントマターに `name` / `description` / `tools` を記載する
3. コミット・プッシュする

`agents/` 配下は `skills/` と同様にディレクトリごと自動検出されるため、`plugin.json` への明示的な列挙は不要です。

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
