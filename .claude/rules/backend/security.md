---
applies_to:
  - "apps/api/**/*.go"
  - "apps/api/**/*.ts"
  - "apps/api/**/*.py"
  - "server/**"
priority: high
category: security
---

# Backend Security

## 適用範囲

バックエンド API のセキュリティに関するルール。入力検証、認可、SQL、シークレット、
ログ出力をカバーする。

## ルール

### MUST

- **SQL は必ず prepared statement / placeholder を使う**。
  文字列連結や `fmt.Sprintf` で SQL を組み立てない
- **すべての API エンドポイントで認証・認可を明示的に確認する**。
  「親 router でかかっているはず」に依存しない
- **シークレット（API キー、DB パスワード、JWT secret）をリポジトリにコミットしない**。
  環境変数 + シークレットマネージャ経由で取得する
- **エラーレスポンスに内部情報を含めない**。スタックトレース、SQL クエリ、内部パスを
  クライアントに返さない
- **すべての外部入力（リクエストボディ、クエリパラメータ、ヘッダ）を検証する**。
  型・長さ・フォーマット・許容値を明示的にチェック
- **個人情報（メール、電話番号、住所、トークン）をログに出力しない**。
  デバッグ用でも禁止

### SHOULD

- レート制限を実装する（特に認証・登録・パスワードリセット系のエンドポイント）
- 認可は role-based ではなく resource-based（「このユーザーがこのリソースを操作できるか」）
  を基本とする
- セッショントークン / API キーには有効期限を設定する
- HTTPS を強制する（HSTS ヘッダ、HTTP からのリダイレクト）

### NIT

- リクエスト ID をログに含めると追跡しやすい
- セキュリティイベント（ログイン失敗、認可違反）は構造化ログで残す

## ❌ 悪い例

```go
// SQL インジェクション
query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", req.Email)
rows, _ := db.Query(query)

// 認可チェック漏れ
func GetOrder(w http.ResponseWriter, r *http.Request) {
    orderID := r.URL.Query().Get("id")
    order := db.FindOrder(orderID) // 他人の注文も取得できてしまう
    json.NewEncoder(w).Encode(order)
}

// 個人情報をログに
log.Printf("user logged in: email=%s, password_hash=%s", user.Email, user.PasswordHash)

// 内部情報の漏洩
if err != nil {
    http.Error(w, err.Error(), 500) // スタックトレースや SQL がそのまま返る
}
```

## ✅ 良い例

```go
// prepared statement
row := db.QueryRowContext(ctx,
    "SELECT id, email FROM users WHERE email = $1",
    req.Email)

// 明示的な認可チェック
func GetOrder(w http.ResponseWriter, r *http.Request) {
    userID := auth.UserIDFromContext(r.Context())
    orderID := r.URL.Query().Get("id")

    order, err := db.FindOrder(ctx, orderID)
    if err != nil { ... }
    if order.UserID != userID {
        http.Error(w, "not found", 404) // 存在を隠すため 404
        return
    }
    json.NewEncoder(w).Encode(order)
}

// PII を含まないログ
log.Info("user logged in", "user_id", user.ID, "request_id", reqID)

// 安全なエラーレスポンス
if err != nil {
    log.Error("internal error", "err", err, "request_id", reqID)
    http.Error(w, "internal server error", 500) // クライアントには汎用メッセージ
}
```

## 根拠

- SQL インジェクションは依然として OWASP Top 10 上位。prepared statement で構造的に防げる
- 認可漏れは IDOR (Insecure Direct Object Reference) の典型例。ルーティングだけに頼ると
  個別エンドポイントで漏れる
- PII をログに残すと、ログ閲覧権限のある人全員に PII が漏れる。GDPR / 個人情報保護法の
  観点でも問題
- エラー詳細の漏洩は攻撃者に内部構造のヒントを与える

## 関連ルール

- `.claude/rules/frontend/security.md` — フロント側の認証情報の取り扱い
- `.claude/rules/backend/architecture.md` — 認可ミドルウェアの設計（あれば）
