# メモリと Obsidian Vault の二重保存

知見は **Claude Code のメモリと Obsidian Vault の両方に書く。** どちらか片方ではない。

## なぜ両方なのか

- **メモリ**（`~/.claude/projects/<プロジェクト>/memory/`）は毎セッション自動で読まれるが、
  このマシンのローカルにしかない
- **Vault**（`~/.claude/vaults.json` の `default`）は開いたときしか読まれないが、デバイス間で
  持ち歩けて、Obsidian が無くなっても Markdown として残る

弱点が逆なので、片方が失われても知見が消えないための冗長化になる。**どちらも本文まで持つ。**
片方を要約だけにすると、残った方が使えなくなって冗長化の意味がなくなる。

## 対応

| メモリの `type` | Vault の置き場 | Vault の `type` |
|---|---|---|
| `feedback`（作業の教訓・規約） | `Resources/<主題カテゴリ>/` | `resource` |
| `project`（進行中） | `Projects/<リポジトリ名>/` | `project` |
| `project`（完結した判断） | `Decisions/` | `decision` |
| `reference`（参照資料） | `Resources/` | `resource` |
| `user`（本人について） | `Resources/` | `note` |

Vault 側のフォルダ名・frontmatter・タグは Vault 自身の規約（ルートの `CLAUDE.md`）に従う。
上の表は対応の目安で、実際の書き出しは `vault-save` スキルに任せる。

**`Projects/` の下はリポジトリ名で切る。** メモリのディレクトリもリポジトリ単位なので、
名前を揃えると両者を突き合わせられる。

## 運用

- **片方を書いたら同じターンでもう片方も書く。** 後回しにすると必ず片方だけになる
- Vault のノート本文に、対応するメモリのファイル名を1行入れる
  （例: `Claude Code memory: feedback_pipe_hides_command_failure.md`）
- メモリ側から Vault を指すときは**パスで書く。** `[[ノート名]]` は Obsidian の記法で、
  Claude Code は解決しない
- **食い違いを見つけたら、勝手にどちらかへ寄せずに差分を提示して聞く。** どちらが新しいかは
  内容を見ないと決まらない

## 既存分の扱い

2026-08-24 時点でメモリに 176 件あり、Vault 側には無い。**新規分から二重保存を始め、既存分は
別途まとめて棚卸しする**（未着手）。

プロジェクト別の内訳は Vault の `CLAUDE.md` に置く。**リポジトリ名をこのファイルに書かない** —
このファイルは公開リポジトリで配布されるため。
