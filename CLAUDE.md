# Kakeibot

個人開発の iOS・Android 家計簿アプリ。人間向けの入口は [README.md](README.md)。

## 作業の進め方

変更したら `make build` と `make test` を通す。PR では CI が同じ 2 つを走らせる。

画面を足したら、デバッグメニュー（`Features/Debug`）にも足す。部品は足さない。

pre-commit の整形で commit が止まったら、差分を確かめてからステージし直す。止まる仕組みは [README の「動かし方」](README.md#動かし方)にある。`--no-verify` で飛ばさない。

## コードの書き方

VoiceOver などのアクセシビリティの対応は入れない。`accessibility` で始まるモディファイアや、読み上げのためだけの値や引数を書かない。

## 文書

作業ごとに、先に読む文書と、終えたら直す文書が決まっている。

| 作業 | 先に読む | 終えたら直す |
| --- | --- | --- |
| 機能・画面を足す | [overview](docs/overview.md)、[roadmap](docs/roadmap.md) | overview、roadmap |
| ターゲット・依存・フォルダを変える | [architecture](docs/architecture.md) | architecture |
| 表の形を変える | [data](docs/data.md) | data。書き出しに響くなら export-format も |
| 書き出しの形式を変える | [export-format](spec/export-format.md) | export-format |
| fixtures を足す・変える | [fixtures](spec/fixtures.md) | fixtures |
| 方針を決める・変える | [decisions](docs/decisions.md) | decisions |
| 作る順番の 1 段を終える | [roadmap](docs/roadmap.md) | roadmap の状態 |
| 対応 OS を変える | [overview](docs/overview.md) | overview、README のバッジ |
| Swift の版・使う技術を変える | [architecture](docs/architecture.md) | architecture、README のバッジ |
| 未検証の項目を確かめる | 各文書の `[!WARNING]` | 結果で本文を書き換え、WARNING から消す |
| 整形・確認の仕組みを変える | [README の「動かし方」](README.md#動かし方) | README、architecture のリポジトリの木 |

どの事実をどの文書に書くかは [.claude/rules/doc-roles.md](.claude/rules/doc-roles.md) にあり、文書を開くと読み込まれる。
