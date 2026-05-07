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

## 更新

```bash
git pull
./install.sh
```
