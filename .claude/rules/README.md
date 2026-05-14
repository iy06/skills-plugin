# Review Rules カタログ

このディレクトリは **pr-review skill が参照するレビュー基準** を格納する。

skill は PR をレビューするとき、まずこの README を読んでカタログを把握し、
変更内容に応じて該当するルールを読み込む。

## レイヤー判定ルール

| パスパターン | 適用ディレクトリ |
|---|---|
| 任意（すべての PR） | `shared/` |
| `apps/web/**`, `**/*.tsx`, `**/*.css` | `frontend/` |
| `apps/api/**`, `**/*.go`（API 配下） | `backend/` |

<!-- 上記はプロジェクトの構造に合わせて書き換えること -->

## ルール一覧

### shared/（全 PR で必ず確認）

| ファイル | 観点 | 概要 |
|---|---|---|
| `shared/git-conventions.md` | コミット規約 | コミットメッセージ、PR タイトルの体裁、変更粒度 |

### frontend/

| ファイル | 観点 | 概要 |
|---|---|---|
| `frontend/security.md` | セキュリティ | XSS、CSP、認証情報のクライアント側保持 |

### backend/

| ファイル | 観点 | 概要 |
|---|---|---|
| `backend/security.md` | セキュリティ | SQLi、認可、シークレット、入力検証 |

<!-- ルールを追加するたびにこの表を更新すること -->

## レビュー観点の優先順位

skill は以下の順序でレビューを実施する：

1. **coding-style** — 規約違反、命名、フォーマット
2. **architecture** — 設計、依存方向、責務分離
3. **testing** — テストの有無・質
4. **security** — セキュリティ違反（最後だが優先度は最高）

## ルールの書き方

新しいルールを追加するときは `_template.md` をコピーして使う：

```bash
cp .claude/rules/_template.md .claude/rules/backend/architecture.md
```

書く際の指針：
- **❌ 悪い例 / ✅ 良い例を必ず入れる**（Claude の判定精度が大きく上がる）
- **frontmatter の `applies_to` を正確に書く**
- **重要度を MUST / SHOULD / NIT で分類する**
- **「根拠」セクションに、なぜこのルールが必要かを書く**（半年後の自分への手紙）

## ルール追加・変更のサイクル

1. PR レビューで Claude が見落とした、または誤検知した
2. PR テンプレの「Claude レビューへのフィードバック」欄に記録
3. ルール追加・変更の PR を作成（テンプレ: `.github/PULL_REQUEST_TEMPLATE/rule_update.md`）
4. ルール本文に **トリガーとなった PR への参照** を必ず残す

これにより、ルールが「なぜそうなったのか」が将来も追える状態を保つ。
