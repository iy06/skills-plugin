---
applies_to:
  - "apps/web/**/*.ts"
  - "apps/web/**/*.tsx"
  - "apps/web/**/*.js"
  - "apps/web/**/*.jsx"
priority: high
category: security
---

# Frontend Security

## 適用範囲

フロントエンドコードのセキュリティに関するルール。XSS、認証情報の取り扱い、外部入力の
扱いをカバーする。

## ルール

### MUST

- **`dangerouslySetInnerHTML` の使用禁止**。やむを得ず使う場合は DOMPurify 等で
  サニタイズ済みの値だけを渡し、コメントで理由を明記
- **API キーや秘密情報をフロントエンドコードに含めない**。`.env` のうち
  `NEXT_PUBLIC_` / `VITE_` などクライアントに露出する prefix の変数に秘密情報を入れない
- **`localStorage` / `sessionStorage` に JWT・リフレッシュトークン・PII を保存しない**。
  認証は httpOnly Cookie を使う
- **外部から受け取った URL をそのまま `href` / `window.location` に渡さない**。
  `javascript:` スキームの混入を防ぐためにプロトコル検証を行う

### SHOULD

- ユーザー入力を表示する箇所では、React のデフォルトエスケープに依存し、独自に
  `innerHTML` を組み立てない
- 外部リンクには `rel="noopener noreferrer"` を付ける
- フォーム送信時は CSRF トークンを含める（バックエンドが要求する場合）

### NIT

- 開発用のデバッグログ（`console.log` で機密情報を出すもの）はリリース前に削除

## ❌ 悪い例

```tsx
// XSS リスク: 検証なしに HTML を挿入
function Comment({ html }: { html: string }) {
  return <div dangerouslySetInnerHTML={{ __html: html }} />;
}

// 認証情報を localStorage に保存
localStorage.setItem("jwt", response.data.token);

// API キーをフロント側に露出
const API_KEY = process.env.NEXT_PUBLIC_OPENAI_KEY; // ❌ クライアントに渡る
```

```tsx
// open redirect リスク
function redirect(url: string) {
  window.location.href = url; // url が "javascript:alert(1)" だと実行される
}
```

## ✅ 良い例

```tsx
import DOMPurify from "dompurify";

// やむを得ず HTML を扱う場合はサニタイズ済みの値だけ
function Comment({ html }: { html: string }) {
  // サニタイズ理由: マークダウンレンダラから受け取った安全な HTML のみを表示
  const safe = DOMPurify.sanitize(html);
  return <div dangerouslySetInnerHTML={{ __html: safe }} />;
}

// 認証は httpOnly Cookie で（サーバ側で Set-Cookie する）
await fetch("/api/login", { credentials: "include", ... });

// API キーはサーバ経由で使う（BFF パターン）
const result = await fetch("/api/proxy/openai", { ... });
```

```tsx
// URL の検証
function safeRedirect(url: string) {
  const parsed = new URL(url, window.location.origin);
  if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
    throw new Error("Invalid protocol");
  }
  window.location.href = parsed.toString();
}
```

## 根拠

- XSS は OWASP Top 10 の常連。React のエスケープを迂回する `dangerouslySetInnerHTML` は
  最も典型的な穴
- localStorage に保存した認証情報は JavaScript から読み取れるため、XSS と組み合わさると
  簡単に盗まれる。httpOnly Cookie なら JavaScript から読めない
- `NEXT_PUBLIC_*` 変数はビルド時にバンドルに含まれ、ブラウザの devtools から閲覧可能

## 関連ルール

- `.claude/rules/backend/security.md` — サーバ側で認証・認可をどう扱うか
- `.claude/rules/shared/git-conventions.md` — シークレットの誤コミット防止
