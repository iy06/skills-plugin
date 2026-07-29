---
applies_to:
  - "**"
# PR でのみ適用する。未完成のコミットにテスト不足を指摘しても直しようがなく、
# fail-fast の邪魔にしかならないため。commit-review はこのルールをスキップする。
applies_at: [pr]
priority: high
category: testing
---

# Testing

## 適用範囲

すべての PR。テストの有無と質に関する規約。**コミット段階では適用しない**（`applies_at: [pr]`）。

## ルール

### MUST

- **バグ修正の PR には、修正前に落ちるテストを含める**。テストが無いと、同じバグが再発しても
  気づけない
- **新規の分岐・エラーパスにはテストを付ける**。ハッピーパスだけのテストは、壊れても通る
- **テストは実装の詳細ではなく振る舞いを検証する**。private メソッドや内部状態ではなく、
  公開インターフェース経由で確認する

### SHOULD

- 不安定要因（現在時刻、乱数、ネットワーク、ファイル I/O）は注入または固定する
- 境界値（0 件、1 件、上限、null / 空文字）のケースを含める
- テスト名は「何をしたら何が起きるか」が読み取れる形にする

### NIT

- テストが 3 つ以上同じ準備コードを繰り返しているならヘルパーに抽出する

## ❌ 悪い例

```ts
// 何を保証しているのか読み取れない。落ちても原因が分からない
it("works", async () => {
  const r = await createUser({ email: "a@example.com" });
  expect(r).toBeTruthy();
});

// 実装の詳細に結合していて、リファクタで無関係に落ちる
it("calls the repository", () => {
  createUser(input);
  expect(repo.insert).toHaveBeenCalled();
});
```

## ✅ 良い例

```ts
// バグ修正に対する回帰テスト。修正前は落ちる
it("大文字小文字違いの email を重複として扱う", async () => {
  await createUser({ email: "user@example.com" });
  await expect(createUser({ email: "USER@example.com" }))
    .rejects.toThrow(DuplicateEmailError);
});

// 境界値。0 件のときの振る舞いを固定する
it("該当ユーザーが 0 件なら空配列を返す", async () => {
  expect(await findUsers({ role: "nonexistent" })).toEqual([]);
});
```

## 根拠

- テストの無いバグ修正は再発を検知できない。「直した」ことの証拠が残らないため、
  半年後に同じ修正を繰り返すことになる
- 実装の詳細に結合したテストは、リファクタのたびに落ちる。落ちるたびに「テストが悪い」と
  判断して直す運用になり、やがてテスト自体が信頼されなくなる
- **このルールを `[pr]` 限定にしている理由**: WIP コミットにテスト不足を指摘しても直しようがない。
  commit 段階で止めるべきはシークレット混入のような「後から直せない事故」であって、
  完成度は PR でまとめて見る

## 関連ルール

- `.claude/rules/shared/git-conventions.md` — 1 PR の粒度（小さく保つとテストも書きやすい）
