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

### 任意：natural-japanese を併せて入れる

grill 系スキルが書く設計書・要件定義書・ループ設計書・理解メモは、
[natural-japanese](https://github.com/coji/natural-japanese)（MIT, coji 作）が入っていれば
提示・保存の直前にそれを通し、冗長な言い回しやリズムの単調さを機械的に検出して直す。

```bash
claude plugin marketplace add coji/natural-japanese
claude plugin install natural-japanese@natural-japanese
```

`uv` が要る（`scripts/lint.py` の実行に使う）。**入れなくてもこのプラグインは動く** —
未インストールなら各スキルは素のまま書く。方針は `shared/japanese-style.md` を参照。

## スキル一覧

| スキル名 | 説明 |
|---|---|
| `session-start-hook` | Claude Code on the web 向けのセッション開始フックを作成する |
| `pr-review` | GitHub の PR を `.claude/rules/` のルールに基づいてレビューし、インラインコメントとサマリーを残す |
| `commit-review` | push / commit 前のローカル差分を fail-fast でチェックし、BLOCK があれば push を止める |
| `grill-me` | ユーザーの実装要望を、徹底的な質問と推奨回答の提示を通じて具体化し、実装前に設計書として合意を取る |
| `grill-you` | 既存コード・機能・概念について調査と解説を行い、追加質問に応じて深掘りすることで理解を深める |
| `grill-product` | アプリの要件を定義し、現在の機能と将来欲しい機能を整理した要件定義書を作成する |
| `grill-loop` | 自律・並列のエージェント開発を「どう回し続けるか」を質問駆動で設計し、ループ設計書と起動物 (ラベル定義・起票雛形・consumer スクリプト・routine prompt・緊急停止手順) を生成する |
| `gui-event-audit` | GUI のイベントを網羅的に列挙し、各イベントの実効を層をまたいで末端まで追跡して、押しても効かない・キャンセルできない・イベント競合などの矛盾を静的解析で発見する |

## エージェント一覧

開発フローの各フェーズ (要件 → 設計 → 実装) の成果物をレビューする subagent です。プラグインをインストールすると Task ツールの subagent として利用でき、対応するスキルの出力を受けて品質確認する下流工程として機能します。

| エージェント名 | 説明 | 上流スキル |
|---|---|---|
| `requirements-review` | 要件定義書 / PRD をルーブリックで検証し、設計フェーズに進んで良いか判定する | `grill-product` |
| `design-review` | 設計書 / アーキテクチャを検証し、要件との対応マップを作って実装に進んで良いか判定する | `grill-me` |
| `code-review` | ローカルの作業ブランチ・コミット範囲・ファイル群の実装をレビューする (GitHub PR レビューは `pr-review` スキルが担当) | — |

## 資産を追加・変更するときの約束

`skills/` と `agents/` はディレクトリごと自動検出されるため、`plugin.json` への明示的な列挙は
不要です。以下はこのリポジトリ内で守る規約です。

- **`description` は「担当フェーズ + 成果物 + 隣接資産との境界」で書く。** トリガとなる発話の
  列挙（「〜と言ったときに必ず使う」）はしない。列挙は網羅できないうえ、同名・近接の資産が
  他プラグインにも存在するため、選択の判断材料にならない
- **`name` はディレクトリ名と一致させる。** 参照はすべて `name` 経由で解決される
- **複数の資産で共有する方針は `shared/` に置き、各資産からは 1 行で参照する。** 同じ指示を
  コピーすると、変更時に片方だけ古くなる
  - `shared/diagram-preview.md` — 図の出し方（grill 系スキル共通）
  - `shared/japanese-style.md` — 散文の成果物の文体（grill 系スキル共通、natural-japanese に委譲）
  - `shared/severity.md` — 指摘の重大度の判定基準（レビュー系スキル / エージェント共通）
  - `shared/debug-residue.md` — デバッグ残骸の既定検出パターン（commit-review の組み込みチェック）
- **利用者が上書きできる既定値は `shared/` に置き、上書き先と同じスキーマにする。** 既定値を
  `examples/rules/` に置くと、そこをコピーしていないリポジトリで機能が丸ごと消える
- **分割の判断基準は「毎回読まれるか」。** そのスキルを最後まで実行しない限り読まれない内容
  （成果物のテンプレート、生成コマンド、条件分岐の先にある出力パターン）は `references/` に
  出し、本体は「いつ・何を・どの順で」に絞る。逆に**毎回読まれるものは本体に置く** — 逐次的な
  会話ステップや、そのスキルが常に出力する表の形は、外に出しても結局読むので削減にならない。
  行数は基準ではなく目安で、200 行を超えたら見直しの合図と考える

## 更新

```
/plugin marketplace update iy06-skills
/plugin update skills-plugin@iy06-skills
```
