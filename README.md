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
