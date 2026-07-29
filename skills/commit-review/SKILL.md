---
name: commit-review
description: push / commit 前のローカル差分を、`.claude/rules/` のうち `applies_at` が commit 段階を含むルールだけで fail-fast にチェックする。シークレット混入とデバッグ残骸は rules が無くても常に検出し、BLOCK が 1 件でもあれば exit 1 で push を止める。git の pre-push hook からの起動を主な用途として想定。マージ可否の総合判定は pr-review skill が担当する。
---

# Commit Review Skill

ローカルのコミット（staged な変更、直前のコミット、または push 予定のコミット群）を、
プロジェクト固有のルールに基づいて fail-fast でレビューする skill。

## pr-review との関係

- **同じルールセット**（`.claude/rules/`）を共有する
- **役割が違う**: pr-review はマージ可否の総合判定、commit-review は push 前の fail-fast
- **ラベルが違う**: pr-review は MUST/SHOULD/NIT、commit-review は BLOCK/WARN
- **出力先が違う**: pr-review は GitHub コメント、commit-review はターミナル
- **判定基準**: ルールの frontmatter `applies_at` で適用フェーズを切り替える
  - `applies_at: [commit, pr]` (デフォルト) → 両方で適用
  - `applies_at: [pr]` のみ → コミット時には適用しない（テスト不足など完成度を問うもの）
  - `applies_at: [commit]` のみ → コミット時のみ適用（コミットメッセージ規約など）

## 実行モード

起動文脈から、以下のいずれかのモードを判断する：

| モード | 対象範囲 | 起動例 |
|---|---|---|
| `staged` | `git diff --cached`（コミット予定の変更） | 「staged を確認」「コミット前にチェック」 |
| `last` | 直前のコミット（`git diff HEAD~1 HEAD`） | 「直前のコミットをレビュー」 |
| `range` | push 予定のコミット群 (`git log @{u}..HEAD`) | pre-push hook、「push 前にチェック」 |
| `commit:<sha>` | 特定のコミット | 「commit abc1234 をレビュー」 |

モードが曖昧な場合は `staged` をデフォルトとする。なお、pre-push hook から呼ばれた
場合は環境変数 `GIT_HOOK=pre-push` が立っている前提で `range` モードを使う。

## 前提

- リポジトリのルートで実行されること（`git rev-parse --is-inside-work-tree` で確認）
- `.claude/rules/` が整備されていること（なければ最後の節を参照）

## 手順

### 1. 実行モードの判定

```bash
# pre-push hook から呼ばれているか
[ "$GIT_HOOK" = "pre-push" ] && MODE=range

# ユーザー指示から判定（staged / last / range / commit:<sha>）

# 対象 diff を取得
case "$MODE" in
  staged)  DIFF=$(git diff --cached) ;;
  last)    DIFF=$(git diff HEAD~1 HEAD) ;;
  range)   DIFF=$(git log @{u}..HEAD --format='%H %s'; git diff @{u}..HEAD) ;;
  commit:*) SHA=${MODE#commit:}; DIFF=$(git show "$SHA") ;;
esac
```

`range` モードでは、レビュー対象のコミット **一覧** も把握する（コミットメッセージ規約の
チェックに必要）：

```bash
git log @{u}..HEAD --format='%H%n%s%n%b%n---'
```

### 2. ルールカタログの読み込み

`.claude/rules/README.md` を読む（存在しない場合は最後の節参照）。

### 3. 該当ルールの選別

変更ファイルパスから対象レイヤーを判定し、該当ディレクトリのルールを読む。
**読み込んだルールのうち、frontmatter で `applies_at` が `[pr]` のみのものはスキップする**。

```
読むべきルール:
- frontmatter に applies_at がない → デフォルト [commit, pr] とみなして読む
- applies_at: [commit, pr] → 読む
- applies_at: [commit] → 読む
- applies_at: [pr] → スキップ（コミット時には適用しない）
```

### 4. レビューの実施

観点の順序は固定: **シークレット → デバッグ残骸 → コミットメッセージ → セキュリティ →
コーディング規約 → アーキテクチャ → その他**。

シークレットとデバッグ残骸は最優先（後述）。

### 5. 結果の出力

ターミナル向けに整形して出力する（[出力フォーマット](#出力フォーマット) 参照）。
BLOCK が 1 件でもあれば **exit code 1** で終了し、push を拒否する。WARN のみなら
exit code 0。

---

## レビューの規律

レビューの規律 A〜D（指摘にルールの引用を付ける / 重要度ラベルを付ける / 指摘ゼロでも報告する /
同種の指摘は集約する）は **pr-review skill の「レビューの規律」に準拠する**。ラベルだけ読み替える:

| pr-review | commit-review | 意味 |
|---|---|---|
| `[MUST]` | `[BLOCK]` | push を止める。セキュリティ違反、シークレット混入、重大な規約違反 |
| `[SHOULD]` | `[WARN]` | 進めてもよいが直すべき。設計の小違反、可読性、TODO 残し |
| `[NIT]` | （出さない） | コミット時にはノイズになるため出力しない |

判断に迷ったら一段下に倒す（BLOCK か迷ったら WARN）。

以下はコミットレビュー特有の規律。

### コミットレビュー特有の規律

#### D. 速度を意識する

コミットレビューは開発体験に直結する。**判断に時間がかかる観点は WARN に倒すか、保留**
する。CI（pr-review）でもう一度全観点でチェックされる前提なので、ローカルでは
「確実に NG」だけを強く拾う。

#### E. WIP コミットを優しく扱う

コミットメッセージに `wip`, `WIP`, `tmp`, `temp` が含まれる場合、未完成前提の指摘
（テスト不足、TODO 残しなど）は出さない。シークレット混入や構造的なバグは
通常通り検出する。

#### F. デバッグログ・残骸の検知

既定の検出パターンは、プラグインルートの `shared/debug-residue.md` を正とする。
diff に **追加** されたものだけを対象とし、rules の有無にかかわらず実施する。

プロジェクト側に `.claude/rules/shared/debug-residue.md` があれば、そちらを優先する。
既定と上書き先はスキーマが同じなので、既定ファイルをコピーして必要な行を削るのが早い。

#### G. シークレット混入の検知

以下のパターンが diff に **追加** されている場合、即 `[BLOCK]`：

- 形状ベース: AWS access key (`AKIA[0-9A-Z]{16}`), GitHub token (`ghp_[A-Za-z0-9]{36}`),
  Slack token (`xox[abp]-...`), Stripe key (`sk_live_...`), OpenAI key (`sk-[A-Za-z0-9]{48}`),
  Anthropic key (`sk-ant-[A-Za-z0-9-]{90,}`)
- 命名ベース: `password = "..."`, `api_key = "..."`, `secret = "..."` で
  リテラル文字列が代入されている（環境変数経由でないもの）
- ファイルベース: `.env`, `.env.local`, `id_rsa`, `*.pem`, `*.p12`, `service-account.json`
  などの追加・変更

検出時は **絶対に値そのものを出力しない**。「`apps/api/config.go:23` に AWS access key
と思しき文字列が追加されています」のようにファイル位置だけ示す。

#### H. コミットメッセージ規約

`range` モードでは、push 予定の全コミットのメッセージをチェックする。
`.claude/rules/shared/git-conventions.md` 等で規約が定義されている場合、それに違反する
コミットを `[BLOCK]` または `[WARN]` で報告する。

```
[WARN] commit abc1234 のメッセージ "update" は rules/shared/git-conventions.md の
  Conventional Commits 規約 (<type>: <subject>) に違反しています。
```

---

## 出力フォーマット

ターミナル向けの出力テンプレートは `references/output-format.md` を参照する
（検出あり / 検出なし / セットアップ未完了 の 3 パターン）。

**exit code**: BLOCK が 1 件でもあれば 1、WARN のみ・問題なしなら 0。

どのパターンでも、末尾に pr-review との関係の説明を必ず添える（同ファイル末尾）。
commit で止められた開発者が「本当にひどいのか、CI でどう扱われるか」を判断できるようにするため。

---

## やってはいけないこと

- **WARN を BLOCK に格上げしない**（push をむやみに止めない）
- **rules に書かれていない好みを指摘しない**（PR 同様）
- **シークレットの値そのものを出力しない**（ログにも残らないように）
- **未ステージの変更を勝手にレビューしない**（モードで明示されたものだけ）
- **コミットを書き換えたり commit --amend を提案しない**（ユーザーの履歴を尊重）
- **`git push --no-verify` を案内しない**（最後の砦を勝手に下ろさない）

---

## ルールが存在しない / 不完全な場合

`.claude/rules/` が存在しない、または空の場合は、組み込み観点のみで簡易チェックを実施し、
セットアップ手順を案内する（出力は `references/output-format.md` のパターン 3）。

組み込みチェック（シークレット、デバッグ残骸）はルールがなくても **必ず実施する**。
これらは普遍的に有害なため。
