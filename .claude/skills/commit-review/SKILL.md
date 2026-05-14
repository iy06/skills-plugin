---
name: commit-review
description: ローカルのコミットを、リポジトリの `.claude/rules/` に定義されたプロジェクト固有のルールに基づいてレビューする。pr-review skill と同じルールセットを共有し、`applies_at` メタによって commit 段階で適用すべきルールだけを選別してチェックする。staged な変更、直前のコミット、または push 予定のコミット群に対して、シークレット混入・デバッグログ残骸・コミットメッセージ規約・セキュリティ違反・コーディング規約違反・アーキテクチャ違反などを検知する。「コミットをレビューして」「commit を見て」「push 前にチェックして」「staged を確認して」と頼まれた時、または git の pre-push hook から起動された時には必ずこの skill を使う。明示的に「skill を使え」と言われなくても起動する。
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

pr-review skill と同じ規律をベースに、コミットレビュー特有の規律を加える。

### 必ず守ること

#### A. 指摘には必ずルールへの引用を付ける

```
[BLOCK] apps/api/db/user.go:42
  rules/backend/security.md「SQL は必ず prepared statement を使う」に違反。
  fmt.Sprintf で SQL を組み立てています。
  → db.QueryContext(ctx, "SELECT ... WHERE id = $1", id) を使ってください。
```

引用元を示せない指摘はしない。

#### B. ラベルは BLOCK / WARN の 2 段階のみ

- `[BLOCK]` — push を止めるレベル。セキュリティ違反、シークレット混入、重大な規約違反
- `[WARN]` — 進めてもよいが直すべき。設計の小違反、可読性、TODO 残し

PR レビューの `NIT` 相当はコミット時にはノイズになるので **出さない**。
迷ったら一段下に倒す（BLOCK か迷ったら WARN）。

#### C. 問題ゼロなら明示的に OK を出す

```
✓ Commit Review: 問題は見つかりませんでした
  確認したルール: 6 件
  確認した変更: 3 files, +89 / -12 lines
```

沈黙させない。

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

以下のパターンを diff から検出し、追加されていれば `[BLOCK]` または `[WARN]`：

| パターン | ラベル | 言語 |
|---|---|---|
| `console.log`, `console.debug` | WARN | JS/TS |
| `debugger;` | BLOCK | JS/TS |
| `print(`, `pprint(`（src 配下） | WARN | Python |
| `fmt.Println`（main 以外） | WARN | Go |
| `dump(`, `dd(`, `var_dump(` | BLOCK | PHP/Laravel |
| `binding.pry`, `byebug` | BLOCK | Ruby |
| `TODO`, `FIXME`, `XXX`（新規追加分のみ） | WARN | 全言語 |
| `.only`, `.skip`（テスト） | BLOCK | JS/TS テスト |

これらは rules に書かなくても skill 側でデフォルト検出する。プロジェクトで例外を
許可したい場合は `.claude/rules/shared/debug-residue.md` を作って上書き可能。

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

### 問題が検出された場合

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Commit Review — 2 BLOCK / 1 WARN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[BLOCK] apps/api/config.go:23
  AWS access key と思しき文字列が追加されています。
  → 環境変数経由で読み込んでください。
  根拠: rules/backend/security.md「シークレットはコードに含めない」

[BLOCK] apps/api/handlers/user.go:42
  rules/backend/security.md「SQL は必ず prepared statement」に違反。
  fmt.Sprintf で SQL を組み立てています。

[WARN] apps/web/src/Login.tsx:15
  console.log が追加されています。リリース前に削除してください。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  確認したルール: 6 件
  確認した変更: 3 files, +89 / -12 lines
  確認したコミット: 2 件 (range mode)

  ❌ BLOCK が 2 件あります。修正してから再度 push してください。
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

→ exit code 1

### 問題がなかった場合

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Commit Review — All clear
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

確認したルール: 6 件
  - rules/shared/git-conventions.md
  - rules/backend/security.md
  - rules/backend/coding-style.md
  - rules/backend/architecture.md
  - (debug-residue / secrets - built-in)

確認した変更: 3 files, +89 / -12 lines
確認したコミット: 2 件 (range mode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

→ exit code 0

### pr-review との比較表示

レビュー結果を出力するときは末尾に必ず以下を添える。これにより開発者は
「commit でブロックされたが、本当にひどいのか、CI でどう扱われるか」を判断できる：

```
このレビューは commit 段階での fail-fast チェックです。
PR 作成後、CI で pr-review skill による総合的なレビューが実行されます。
誤検知や疑問があれば --no-verify でスキップできますが、PR でも同じ指摘が
出る可能性が高い点に注意してください。
```

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

`.claude/rules/` が存在しない、または空の場合：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⚠ Commit Review — セットアップ未完了
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.claude/rules/ が存在しないため、組み込み観点のみで簡易チェックを実施します。
（シークレット混入 / デバッグ残骸のみ）

組み込みチェック結果:
[BLOCK] apps/api/config.go:23 — シークレットの混入が疑われます

プロジェクト固有のルールを整備するには:
  cp -r path/to/examples/rules .claude/rules

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

組み込みチェック（シークレット、デバッグ残骸）はルールがなくても **必ず実施する**。
これらは普遍的に有害なため。

---

## 出力例（参考実行）

```
$ claude /commit-review
[Claude が staged モードで実行]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Commit Review — 1 WARN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[WARN] apps/web/src/utils/api.ts:45
  console.log が追加されています。
  根拠: 組み込みチェック (debug residue)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  確認したルール: 4 件
  確認した変更: 1 file, +12 / -3 lines

  ⚠ WARN が 1 件ありますが、push はブロックされません。
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

→ exit code 0 (WARN のみ)
