# skills-plugin

Claude Code のスキルを GitHub で管理するリポジトリです。

## 構造

```
skills/
  <skill-name>/
    SKILL.md       # スキルの定義ファイル
```

## インストール

リポジトリをクローンして `install.sh` を実行すると、すべてのスキルが `~/.claude/skills/` にインストールされます。

```bash
git clone https://github.com/iy06/skills-plugin.git
cd skills-plugin
./install.sh
```

## スキルの追加

1. `skills/<skill-name>/` ディレクトリを作成する
2. `SKILL.md` を作成する（フロントマターに `name` と `description` を記載）
3. コミット・プッシュする

### SKILL.md の形式

```markdown
---
name: skill-name
description: スキルの説明。Claude Code がいつこのスキルを使うかを記述する。
---

# スキルのタイトル

スキルの内容をここに書く。
```

## スキル一覧

| スキル名 | 説明 |
|---|---|
| session-start-hook | Claude Code on the web 向けのセッション開始フックを作成する |
| grill-me | ユーザーの実装要望を、徹底的な質問と推奨回答の提示を通じて具体化し、実装前に設計書として合意を取るためのスキル |
| grill-you | 既存コード・機能・概念について、Claude が調査と解説を行い、追加質問に応じて深掘りすることで対象の理解を深めるためのスキル |
| grill-product | 特定のアプリの要件を定義し、現在の機能と将来欲しい機能を整理した要件定義書を作成するためのスキル。機能の取捨選択を Claude が能動的に提案する |

## 更新

```bash
git pull
./install.sh
```
