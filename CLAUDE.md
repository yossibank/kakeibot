# Kakeibot

個人開発の iOS・Android 家計簿アプリ。人間向けの入口は [README.md](README.md)。

## 作業の進め方

変更したら `make build` を通す。

commit の前に [pre-commit](https://pre-commit.com/)（`.pre-commit-config.yaml`）が、Swift を SwiftFormat で整形する。直して止まったら、差分を確かめてステージし直す。`--no-verify` で飛ばさない。

## 文書

作業ごとに、先に読む文書と、終えたら直す文書が決まっている。

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
| 整形・確認の仕組みを変える | [README](README.md) の「動かし方」 | README、architecture のリポジトリの木 |

どの事実をどの文書に書くかは [.claude/rules/docs.md](.claude/rules/docs.md) にあり、文書を開くと読み込まれる。
