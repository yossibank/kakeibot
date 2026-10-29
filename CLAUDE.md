# Kakeibot

個人開発の iOS・Android 家計簿アプリ。人間向けの入口は [README.md](README.md)。

## 作業の進め方

確かめるコマンドと、それを通す時は次のとおり。

| 場面 | 決まり |
| --- | --- |
| 変更した | `make verify` を通す。出力は成否と失敗の箇所だけで、失敗したときは全ログのパスが最後の行にある |
| PR を作る前 | テストは CI で走らせず、手元で `make test` を 1 回通す。結果は PR の本文の「確認」に書く |
| push し直す | Swift か fixtures を変えたときだけ、`make test` を通し直す |
| 文書だけの PR | `make test` を走らせない |
| ウィジェットの見た目を変えた | `make snapshot SNAPSHOT=widget` で描いて確かめる。PNG は `.build/snapshots/widget/` に出る |
| 動きの不具合を確かめる | claude-config の `ui-record` のスキルで録画して確かめる |

## コードの書き方

VoiceOver などのアクセシビリティの対応は入れない。`accessibility` で始まるモディファイアや、読み上げのためだけの値や引数を書かない。

## 構成

ファイルとフォルダの置き場所と名前は、[architecture の「名前の決まり」](docs/architecture.md#名前の決まり)に従う。共通の構成は、claude-config の `docs/architecture-ios.md` にある。

## 文書

作業ごとに、先に読む文書と、終えたら直す文書が決まっている。

| 作業 | 先に読む | 終えたら直す |
| --- | --- | --- |
| 機能・画面を足す | [overview](docs/overview.md)、[roadmap](docs/roadmap.md) | overview、roadmap |
| ターゲット・依存・フォルダを変える、ファイルを足す・名前を変える | [architecture](docs/architecture.md) | architecture |
| 表の形を変える | [data](docs/data.md)、[data-settings](docs/data-settings.md)、[data-sync](docs/data-sync.md) | 変えた表の文書。書き出しに響くなら export-format も |
| 書き出しの形式を変える | [export-format](spec/export-format.md) | export-format |
| fixtures を足す・変える | [fixtures](spec/fixtures.md) | fixtures |
| 画面の言葉・型の名前を足す・変える | [glossary](docs/glossary.md) | glossary |
| 方針を決める・変える | [decisions](docs/decisions/) の、`docs-section.sh` で探した節だけ | decisions |
| 作る順番の 1 段を終える | [roadmap](docs/roadmap.md) | roadmap の状態 |
| 対応 OS を変える | [overview](docs/overview.md) | overview、README のバッジ |
| Swift の版・使う技術を変える | [architecture](docs/architecture.md) | architecture、README のバッジ |
| 未検証の項目を確かめる | 各文書の `[!WARNING]` | 結果で本文を書き換え、WARNING から消す |
| 整形・確認の仕組みを変える | [README の「動かし方」](README.md#-動かし方) | README、architecture のリポジトリの木 |

spec の文書の役割は [.claude/rules/doc-roles.md](.claude/rules/doc-roles.md) にあり、文書を開くと読み込まれる。
