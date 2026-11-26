# Kakeibot

個人開発の iOS・Android 家計簿アプリ。人間向けの入口は [README.md](README.md)。

## 作業の進め方

確かめるコマンドと、それを通す時は次のとおり。

| 場面 | 決まり |
| --- | --- |
| 変更した | `make verify` を通す。出力は成否と失敗の箇所だけで、失敗した時は全ログのパスが最後の行にある |
| PR を作る前 | テストは CI で走らせず、手元で `make test` を 1 回通す。結果は PR の本文の「確認」に書く |
| push し直す | Swift か fixtures を変えた時だけ、`make test` を通し直す |
| 文書だけの PR | `make test` を走らせない |
| 見た目を変えた | 当たるセットを `make snapshot SNAPSHOT=<セット>` で描いて確かめる。セットは `.claude/snapshots/` の下にあり、PNG は `.build/snapshots/<セット>/` に出る |
| 動きの不具合を確かめる | claude-config の `ui-record` のスキルで録画して確かめる |

## コードの書き方

VoiceOver などのアクセシビリティの対応は入れない。`accessibility` で始まるモディファイアや、読み上げのためだけの値や引数を書かない。

`floatingInput` を使う画面は、外側を `FloatingInputReader` で包む。`GeometryReader` で包まない。

## 構成

ファイルとフォルダの置き場所と名前は、[architecture-naming](docs/architecture-naming.md) に従う。共通の構成は、claude-config の `docs/app/ios-architecture.md` にある。

## 文書

作業ごとに、先に読む文書と、終えたら直す文書が決まっている。文書の場所は、README の「文書」の表にある。

| 作業 | 先に読む | 終えたら直す |
| --- | --- | --- |
| 機能・画面を足す | overview、roadmap、architecture-parts | overview、roadmap、architecture-screens の「画面とフォルダ」 |
| iOS のターゲット・依存・フォルダを変える、ファイルを足す・名前を変える | architecture、architecture-packages、architecture-packages-app、architecture-naming | 先に読む文書のすべて |
| Android のモジュール・依存・フォルダを変える、ファイルを足す・名前を変える | iOS の行の文書も読む。architecture-android、architecture-android-app、architecture-android-flow | 先に読む文書のすべて |
| 画面の組み立て・監視・通知とウィジェットの流れを変える | architecture-screens、architecture-screens-flow | architecture-screens、architecture-screens-flow |
| 表の形を変える | data、data-budget、data-settings、data-sync | 変えた表の文書。書き出しに響くなら export-format も |
| 書き出しの形式を変える | export-format | export-format |
| fixtures を足す・変える | fixtures | fixtures |
| 画面のモデルのテストを足す・消す・名前を変える | scenarios | `spec/scenarios/models.tsv`。違いを見つけたら scenarios も |
| 画面の言葉・型の名前を足す・変える | glossary | glossary |
| 方針を決める・変える | decisions の索引から選び、`docs-section.sh` で探した節だけ | decisions。文書を足したら、索引も |
| 作る順番の 1 段を終える | roadmap | roadmap の状態 |
| 対応 OS を変える | overview | overview、README の技術のアイコンと実行環境 |
| Swift の版・使う技術を変える | architecture | architecture、README の技術のアイコンと実行環境 |
| 未検証の項目を確かめる | 各文書の `[!WARNING]` | 結果で本文を書き換え、WARNING から消す |
| 整形・確認の仕組みを変える | development | development、architecture のリポジトリの表 |

spec の文書の役割は [.claude/rules/doc-roles.md](.claude/rules/doc-roles.md) にあり、文書を開くと読み込まれる。
