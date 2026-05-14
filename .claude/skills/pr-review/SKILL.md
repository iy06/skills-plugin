---
name: pr-review
description: GitHub の Pull Request を、リポジトリの `.claude/rules/` に定義されたプロジェクト固有のルールに基づいてレビューする。コーディング規約・アーキテクチャ・テスト戦略・セキュリティの観点から diff を精査し、個別の問題箇所には GitHub のインラインコメント、全体にはサマリーコメントを残す。「PR をレビューして」「コードレビューして」「review this PR」「PR の指摘をして」と頼まれた時、GitHub Actions の `pull_request` イベントで自動起動された時、`@claude` メンションで PR レビューを依頼された時には必ずこの skill を使う。プロジェクトの規約に従った構造化されたレビューを提供する目的であれば、明示的に「skill を使え」と言われなくても起動する。
---

# PR Review Skill

GitHub の Pull Request を、プロジェクト固有の規約に基づいて構造的にレビューする skill。

## 設計思想

- **このスキル**は汎用のレビューエンジン。レビューの手順・規律・コメントの残し方を担当する
- **規約そのもの**はプロジェクトの `.claude/rules/` に格納され、各プロジェクトが管理する
- レビューの質はルールの質に依存する。ルールに書かれていないことは指摘しない

## 前提

以下のいずれかの環境で動くことを想定：

1. **GitHub Actions 経由**（`anthropics/claude-code-action@v1`）— `pull_request` イベントで起動
2. **ローカルの Claude Code**— ユーザーが PR 番号を指定して依頼

必要な権限・ツール：

- `gh` CLI（`gh pr view`, `gh pr diff`, `gh pr comment`）
- `mcp__github_inline_comment__create_inline_comment` — インラインコメント投稿用の MCP ツール。
  GitHub Actions の `claude_args` で必ず `--allowedTools` に含めておくこと。これがないと
  個別行へのコメントができず、全体への top-level コメントしか残せない。

## レビュー手順

以下を上から順に実行する。

### 1. PR コンテキストの取得

```bash
gh pr view "$PR_NUMBER" --json title,body,files,additions,deletions,baseRefName,headRefName
gh pr diff "$PR_NUMBER"
```

PR が大きすぎる場合（変更行数 > 1000、変更ファイル数 > 30）は、ユーザー（または自動レビュー
ならサマリーコメント）に「この PR はレビュー範囲を絞ることを推奨します」と伝えた上で、
最も重要そうな変更（新規ファイル、設定変更、認証/権限関連）に絞ってレビューする。

### 2. ルールカタログの読み込み

`.claude/rules/README.md` を必ず最初に読む。これはルールのインデックス。

カタログが存在しない場合：
- `.claude/rules/` 配下のファイル一覧を `ls` で取得
- 各ファイルの先頭（frontmatter + 最初の見出し）だけを `head -20` で覗いて把握
- それでも構造が不明なら、サマリーコメントで「`.claude/rules/README.md` を整備することを
  推奨します」と伝え、見つかったルールだけでレビューを進める

### 3. 対象レイヤーの判定とルール読み込み

`gh pr view --json files` で取得した変更ファイルパスから、適用するレイヤーを判定する。

判定ロジック（プロジェクトによって `.claude/rules/README.md` で上書き可能）：

| パスパターン | 読むルール |
|---|---|
| 任意（すべての PR） | `.claude/rules/shared/*.md` |
| `apps/web/**`, `frontend/**`, `**/*.tsx`, `**/*.css` などフロントエンド系 | `.claude/rules/frontend/*.md` |
| `apps/api/**`, `backend/**`, `server/**`, `**/*.go`（API 配下）など | `.claude/rules/backend/*.md` |
| `infra/**`, `terraform/**`, `.github/**` など | 該当があれば `.claude/rules/infra/*.md` |

該当レイヤーのルールは **全ファイル読み込む**。判定が曖昧なら両方読む。読み過ぎる方が
見逃しよりマシ。

各ルールファイルに frontmatter で `applies_to` が定義されている場合は、それを尊重する。

### 4. レビューの実施

観点の順序は固定する：**coding-style → architecture → testing → security**。
セキュリティは最後に来るが優先度は最高（後述の MUST ラベル基準を参照）。

diff の各ハンクについて、読み込んだルールに照らして問題がないか確認する。

### 5. コメントの投稿

詳細は [コメント投稿の使い分け](#コメント投稿の使い分け) を参照。

すべて投稿し終わったら、**レビュー結果の要約をチャット返答にも書かない**こと
（GitHub Actions では Claude のテキスト出力は使われない。すべて GitHub 上にコメントとして
残す）。

---

## レビューの規律（最重要）

このセクションを徹底することがレビュー品質の8割を決める。

### 必ず守ること

#### A. 指摘には必ずルールへの引用を付ける

すべての指摘は、`.claude/rules/` 配下のどのファイル・どの記述に基づくのか明示する。

**OK 例**:
> [MUST] `.claude/rules/backend/security.md` の「SQL は必ず prepared statement を使う」
> に違反しています。`fmt.Sprintf` で SQL を組み立てているため SQL インジェクションの
> リスクがあります。`db.PrepareContext` を使ってください。

**NG 例**（引用なし）:
> SQL インジェクションのリスクがあるので prepared statement を使った方が良いです。

引用元を示せない指摘は **しない**。これが false positive を抑える最大の規律。

#### B. 重要度ラベルを必ず付ける

すべての指摘の先頭に、以下のいずれかを付ける：

- `[MUST]` — マージブロッカー。セキュリティ違反、データ破壊リスク、規約への明確な違反
- `[SHOULD]` — 強く推奨。設計上の問題、可読性を著しく損なう、テスト欠如
- `[NIT]` — 細かい指摘。スタイル、命名、些細な改善（無視可）

判断に迷ったら一段下に倒す（`[MUST]` か迷ったら `[SHOULD]`、`[SHOULD]` か迷ったら
`[NIT]`）。`[MUST]` は本当にマージを止めるべき時だけに使う。

#### C. 指摘ゼロでも必ずサマリーを残す

問題が見つからなかった場合も、`gh pr comment` で以下のような報告を残す。沈黙は禁止。

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

#### D. 同種の指摘は集約する

同じ問題が複数ファイルにある場合、代表 1〜2箇所にインラインコメントを残し、サマリーで
「他に N 箇所同様の問題があります」と書く。同じコメントを10連発するのは禁止。

### やってはいけないこと

- **ルールに書かれていない好み・一般論を指摘しない**（最重要）
- **曖昧な指摘をしない**：「〜した方が良いかもしれません」「個人的には〜」は禁止
- **手元で動かしていない動作確認を断言しない**：「これは動きません」ではなく「ルール X に
  違反します」と書く
- **元の実装の悪口を書かない**：レビュー対象は diff であり、人ではない
- **`gh pr review --approve` や `--request-changes` を勝手に発行しない**：これは人間の
  権限。コメントを残すだけにとどめる

---

## レイヤー判定の補足

### モノレポでパスから判定する場合

プロジェクトのディレクトリ規約に従う。`.claude/rules/README.md` に判定ルールが書かれて
いればそれを最優先する。書かれていなければ、以下の慣用パターンで判定：

```
frontend: apps/web/**, web/**, frontend/**, **/*.tsx, **/*.jsx, **/*.vue, **/*.svelte
backend:  apps/api/**, api/**, backend/**, server/**, services/**
shared:   packages/**, libs/**, shared/**, configs/**, scripts/**
infra:    infra/**, terraform/**, .github/**, docker/**, k8s/**
```

### 1つの PR が複数レイヤーをまたぐ場合

両方（または全部）のルールを読む。レイヤー横断の規約違反（例：API の型変更にフロントの
追従がない）も指摘対象になり得るので、横断的に見ること。

---

## コメント投稿の使い分け

### インラインコメント（特定行への指摘）

**ツール**: `mcp__github_inline_comment__create_inline_comment`

**使う場面**:
- 具体的なコード行に対する指摘
- 修正提案（suggestion ブロックで具体的な置換を提案できる）

**フォーマット**:

```markdown
[MUST] `.claude/rules/backend/security.md` の「ユーザー入力は必ず検証する」に違反。

`req.Body` のフィールド `email` がバリデーションされていません。フォーマット検証と
長さ制限を追加してください。

```go
// 修正例
if err := validateEmail(req.Email); err != nil {
    return badRequest(w, err)
}
```
```

### サマリーコメント（PR 全体への top-level コメント）

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

---

## ルールが見つからない・適用判定が曖昧なとき

### `.claude/rules/` が存在しない

サマリーコメントで以下を残す：

```markdown
## Claude Review — セットアップ未完了

このリポジトリには `.claude/rules/` が存在しないため、プロジェクト固有のルールに
基づくレビューができません。

pr-review skill の examples/rules/ をコピーしてセットアップしてください。
```

そのうえで、**一般的な観点での簡易レビュー** に切り替える（セキュリティ・明らかなバグ
のみ）。ルールに基づかない指摘は `[SUGGEST]` ラベルを付け、`[MUST]` は付けない。

### ルールに該当するかどうか曖昧

引用できる根拠がなければ指摘しない。代わりにサマリーの「レビューしきれなかった観点」と
してメモに残し、ルール追加の検討材料にしてもらう：

```markdown
### レビューしきれなかった観点
`apps/api/handlers/user.go` の認可ロジックに気になる点があったが、認可についての
ルールが `.claude/rules/backend/` に見当たらなかったため指摘を見送った。
ルール追加を検討してください。
```

---

## 改善サイクルへの貢献

このレビューは「ルール→レビュー→フィードバック→ルール改善」のサイクルの一部。
サイクルを回すために、レビュー時に以下を必ず行う：

1. **サマリーに「確認したルール一覧」を残す**（透明性）
2. **ルールにないが気になった観点を「レビューしきれなかった観点」として記録**
3. **PR テンプレに「Claude レビューへのフィードバック」欄がある前提で、そこに記入を促す
   フッターをサマリーに添える**

これにより、人間レビュアーが「Claude が見落とした」「Claude の誤検知だった」を後から
記録でき、ルール更新の起点になる。

---

## 出力例（参考）

完全な実行イメージ：

1. `gh pr view 123 --json files` → `apps/web/src/Login.tsx`, `apps/api/handlers/auth.go` が変更
2. `.claude/rules/README.md` を読む
3. `apps/web/**` → `.claude/rules/frontend/*.md` を全部読む
4. `apps/api/**` → `.claude/rules/backend/*.md` を全部読む
5. `.claude/rules/shared/*.md` も全部読む
6. diff を 4 観点（style → architecture → testing → security）で順に見る
7. 個別問題 3 件 → `mcp__github_inline_comment__create_inline_comment` で各行にコメント
8. 全体サマリー 1 件 → `gh pr comment` でレビュー結果と確認したルール一覧を投稿
9. レビュー結果を Claude のチャット返答には書かない

---

## 関連ファイル

このスキルは単体で動くが、以下を `.claude/rules/` 配下に整備するとレビュー品質が大きく
向上する：

- ルールテンプレ → `examples/rules/_template.md`
- ルールカタログ雛形 → `examples/rules/README.md`
- GitHub Actions ワークフロー → `examples/workflows/claude-review.yml`
- PR テンプレ（改善サイクル用） → `examples/pr_templates/pull_request_template.md`
