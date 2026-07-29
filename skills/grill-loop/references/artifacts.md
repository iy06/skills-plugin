# ループ起動物の雛形

`grill-loop` の Step 8 で生成する起動物のテンプレート集。**設計書に合意できてから**読む。

いずれも雛形なので、設計書で決めた並列数・timeout・全体停止条件・マージ条件・許可 glob を
必ず穴埋めすること。既存で足りているもの（例: Step 2 で見つかった既存ラベル）は再生成しない。

## 8-1. ラベル定義コマンド一式

```bash
gh label create loop:ready   --color 0e8a16 --description "着手可"
gh label create loop:wip     --color fbca04 --description "作業中"
gh label create merge:auto   --color 1d76db --description "条件を満たせば自動マージ可"
gh label create merge:manual --color b60205 --description "人間マージ必須"
```

## 8-2. feature レーンの起票コマンド雛形

`grill-product` / `grill-me` の成果を issue 化する。**完了条件ブロックを本文に埋め込む**のが肝。

```bash
gh issue create \
  --title "<機能名>" \
  --label loop:ready,merge:manual \
  --body "$(cat <<'EOF'
## 背景
<なぜやるか。grill-product の要件から>

## 設計
<grill-me の設計書へのリンク、または要約を貼付>

## 完了条件（機械検証できる形で）
- [ ] <テスト名> が pass する
- [ ] 既存テストが green のまま
- [ ] <検証コマンド> が exit 0
EOF
)"
```

## 8-3. consumer スクリプト

`loop:ready` を取得 → `loop:wip` 付与 → worktree 作成 → `timeout <X>m claude -p "/goal <完了条件>"`
→ PR 作成 → ラベル更新、を並列 N 本で回す骨子。排他・エラー処理は運用に合わせて補強する。

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- 緊急停止（論点 8）: 全ループが冒頭でチェックして自主停止 ---
if [ -f .loop-stop ] || gh label list | grep -q '^loop:halt'; then
  echo "emergency stop is set. aborting."; exit 0
fi

N=<並列数>            # 同時 worktree 数（初期 2〜3）
TIMEOUT=<X>m         # 1 反復の壁時計上限
DAILY_MAX=<日次上限>  # その日に消化する issue 数の上限

# --- 全体停止判定（論点 5）: 満たされていれば起動しない ---
READY=$(gh issue list --label loop:ready --state open --json number --jq 'length')
if [ "$READY" -eq 0 ]; then
  echo "queue empty. nothing to do."; exit 0
fi

run_one() {
  local issue="$1"
  # 排他（論点 8）: ready → wip（他エージェントが同じ issue を取らない）
  gh issue edit "$issue" --remove-label loop:ready --add-label loop:wip

  # 直近コミットが bot ならスキップ（bot 往復ループ防止, 論点 8）。対象ブランチが既にある場合のみ判定。

  local wt="../wt-$issue"
  git worktree add -b "loop/issue-$issue" "$wt"

  # 完了条件を issue 本文から取り出して /goal に渡す
  local goal; goal=$(gh issue view "$issue" --json body --jq '.body')

  # 個別停止（論点 5）: goal 達成 + ターン上限 + timeout の三重で必ず止める
  ( cd "$wt" && timeout "$TIMEOUT" claude -p "/goal $goal" ) \
    || echo "issue $issue: timed out or failed"

  # PR 作成し、マージポリシー（論点 6）に沿ってラベル付け
  ( cd "$wt" && git push -u origin "loop/issue-$issue" \
      && gh pr create --fill --label merge:manual )
  # auto 条件を満たす対象なら: --label merge:auto を付け、gh pr merge --auto を併用

  gh issue edit "$issue" --remove-label loop:wip
  git worktree remove "$wt" --force
}
export -f run_one

# 並列 N 本で起動（DAILY_MAX 件まで）
gh issue list --label loop:ready --state open --limit "$DAILY_MAX" \
    --json number --jq '.[].number' \
  | xargs -P "$N" -I{} bash -c 'run_one "$@"' _ {}
```

## 8-4. routine を選んだ場合の prompt 文面

論点 3 で routine を選んだときのみ。**コネクタを最小化し、やらないことを明記する**
（無人実行なので暴走を防ぐ）。

```
毎朝、リポジトリ <owner/repo> の loop:ready かつ merge:manual の issue を上から <日次上限> 件まで消化する。
各 issue について: wip に遷移 → 完了条件（issue 本文）を /goal で達成 → PR を作成（ドラフト可）→ wip を外す。

やらないこと:
- マージはしない（人間が確認する）
- loop:ready が 0 件なら何もせず終了する
- 完了条件が本文に無い issue はスキップし、その旨コメントする
- <許可 glob> の外側を変更する PR は作らない

使用ツール: gh（issue / pr）と git のみ。それ以外のコネクタは使わない。
```

## 8-5. 緊急停止手順の README 断片

```markdown
## ループの緊急停止

全ループは起動時にこれをチェックし、あれば自主停止する:

- **stop ファイル**: リポジトリ直下に `.loop-stop` を作る（`touch .loop-stop`）
- **停止ラベル**: `loop:halt` ラベルを付ける（`gh label create loop:halt`）

解除は削除するだけ（`rm .loop-stop` / ラベル削除）。走行中の反復は個別 `timeout` で自然に終わる。
```
