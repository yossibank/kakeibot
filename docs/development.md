# 開発

> [!NOTE]
> 要る道具と、よく使うコマンドが分かる。
> 実行環境の版は [README](../README.md#-実行環境) にある。

## 🧰 道具

Xcode と [Homebrew](https://brew.sh/) が要る。Android は [Android Studio](https://developer.android.com/studio) と、その SDK が要る。ほかの道具は `make setup` で入る。

| 道具 | 使い道 |
| --- | --- |
| [jq](https://jqlang.org/) | テストに使うシミュレーターを選ぶ（`scripts/find-simulator.sh`）。JSON を整形する（`scripts/json-format.sh`） |
| [Mint](https://github.com/yonaskolb/Mint) | SwiftFormat と LicensePlist の版をそろえる（`Mintfile`） |
| [pre-commit](https://pre-commit.com/) | commit の前の確認を動かす |
| [xcbeautify](https://github.com/cpisciotta/xcbeautify) | ビルドとテストの出力を読みやすくする |

> [!NOTE]
> commit の前に pre-commit が、ステージした Swift と JSON を整形する。直したファイルがあると commit は止まるので、`git add` して commit し直す。

## 🚀 コマンド

よく使うコマンドを、次の表に挙げる。

| 対象 | コマンド |
| --- | --- |
| 道具を入れ、hook を入れる | `make setup` |
| Xcode でワークスペースを開く | `make open` |
| ブランチのワークツリーを Xcode で開く | `make open BRANCH=feat/...` |
| 変更の確認（文書・JSON の整形・Swift の書き方・余白の値・両 OS のテストとビルド。出力は成否と失敗の箇所だけ） | `make verify` |
| 文書の一致と書き方、JSON の整形だけを確かめる（文書だけの変更） | `make verify-docs` |
| iOS のビルド（シミュレーター） | `make build` |
| テストのコンパイルだけ（走らせない） | `make test-build` |
| テスト（`ios/Kakeibot.xctestplan`、シミュレーター。出力は `.build/test.log` にも残る） | `make test` |
| 画面の部品を PNG に描く（下の注） | `make snapshot SNAPSHOT=widget` |
| Android のビルド（デバッグの APK） | `make android-build` |
| Android の Core と Store のテスト | `make android-test` |
| Swift と JSON の整形 | `make format` |
| ライセンスの一覧を作り直す（部品やフォントを足したとき） | `make licenses` |

`make snapshot` は claude-config の `ui-snapshot` を使う。セットは `.claude/snapshots/` の下の名前で、出力は `.build/snapshots/<セット>/` に出る。

## 📱 画面を直接開く

DEBUG のビルドは、起動の引数 `-open` で設定の画面を直接開く。`settings` なら設定のシートを、`SetupItem` の名前（`homeSections` など）ならその画面を開く。

```sh
xcrun simctl launch booted com.yossibank.kakeibot -open homeSections
```
