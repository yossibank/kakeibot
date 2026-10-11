# Kakeibot

個人開発の iOS・Android 家計簿アプリ。人間向けの入口は [README.md](README.md)。

## 作業と文書

| 作業 | 先に読む | 終えたら直す |
| --- | --- | --- |
| 機能・画面を足す | [overview](docs/overview.md)、[roadmap](docs/roadmap.md) | overview、roadmap |
| ターゲット・依存・フォルダを変える | [architecture](docs/architecture.md) | architecture |
| 表の形を変える | [data](docs/data.md) | data。書き出しに響くなら export-format も |
| 書き出しの形式を変える | [export-format](spec/export-format.md) | export-format |
| 方針を決める・変える | [decisions](docs/decisions.md) | decisions |
| 作る順番の 1 段を終える | [roadmap](docs/roadmap.md) | roadmap の状態 |
| 対応 OS・Swift の版を変える | [overview](docs/overview.md) | overview、README のバッジ |
| 未検証の項目を確かめる | 各文書の `[!WARNING]` | 結果で本文を書き換え、WARNING から消す |
| 整形・確認の仕組みを変える | [README](README.md) の「準備」 | README、architecture のリポジトリの木 |

コードを変えて文書の記述が古くなったら、同じコミットで直す。文書を書く決まりは [.claude/rules/docs.md](.claude/rules/docs.md) にあり、文書を開くと読み込まれる。

commit の前に [pre-commit](https://pre-commit.com/)（`.pre-commit-config.yaml`）が、Swift を SwiftFormat で整形する。直して止まったら、差分を確かめてステージし直す。`--no-verify` で飛ばさない。

## 言語

- 思考・回答・途中経過・報告は、すべて日本語で書く。
- 英語の資料を読んだ直後や、長い会話の後半でも切り替えない。
- 原文を引用するときは原文のままでよいが、説明は日本語で書く。

## 書き方

- コードにも設定にもコメントを書かない。
- 文書は短く、見出しと表で整理する。

## 追加と主張

- 頼まれていないものを足すとき、または「これが必要だ」と主張するときは、それが無い状態で何が壊れるかを先に再現する。
- 追加した後に動くことを確かめても、必要だった証明にはならない。
- 壊れることを再現できなければ実装せず、提案に留める。
- 確かめていないことは「未検証」と書く。推測を断定で書かない。
- 報告には「無い状態で試したらこうなった」を含める。
- 自分で思いついた追加は、実装せずに提案に留める。「必要なら作ります」と言った直後に作り始めない。
- 頼まれたものの実装そのものには、この節を適用しない。
