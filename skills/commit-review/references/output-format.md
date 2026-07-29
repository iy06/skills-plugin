# commit-review の出力フォーマット

ターミナルに出す 3 パターンのテンプレート。結果を出力する段階で読む。

どのパターンでも、末尾には「pr-review との関係」（このファイル末尾）を必ず添える。

## 1. 問題が検出された場合

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

BLOCK が 1 件でもあれば **exit code 1**。WARN のみなら 0（push はブロックしない）。

## 2. 問題がなかった場合

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

→ exit code 0。**沈黙させないこと。** 問題ゼロでも確認範囲を明示する。

## 3. `.claude/rules/` が存在しない / 空の場合

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

## 末尾に必ず添えるもの

開発者が「commit で止められたが、本当にひどいのか、CI でどう扱われるか」を判断できるようにする。

```
このレビューは commit 段階での fail-fast チェックです。
PR 作成後、CI で pr-review skill による総合的なレビューが実行されます。
指摘に納得できない場合は、誤検知として `.claude/rules/` に例外を追記するか、
ルール自体の見直しを検討してください（同じ指摘は PR でも出る可能性が高いため）。
```
