# 開発

> [!NOTE]
> 要る道具と、よく使うコマンドが分かる。
> 実行環境の版は [README](../README.md#-実行環境) にある。

## 🧰 道具

Xcode と [Homebrew](https://brew.sh/) が要る。Android は [Android Studio](https://developer.android.com/studio) と、その SDK が要る。ほかの道具は `make setup` で入る。

| 道具 | 使い道 |
| --- | --- |
| [jq](https://jqlang.org/) | テストに使うシミュレーターを選ぶ（`scripts/find-simulator.sh`）。JSON を整形する（`scripts/json-format.sh`） |
| [ktlint](https://pinterest.github.io/ktlint/) | Kotlin を整形し、書き方を確かめる（`android/.editorconfig`）。版は Makefile の `KTLINT_VERSION` にそろえる |
| [Mint](https://github.com/yonaskolb/Mint) | SwiftFormat と LicensePlist の版をそろえる（`Mintfile`） |
| [pre-commit](https://pre-commit.com/) | commit の前の確認を動かす |
| [xcbeautify](https://github.com/cpisciotta/xcbeautify) | ビルドとテストの出力を読みやすくする |

> [!NOTE]
> commit の前に pre-commit が、ステージした Swift・Kotlin・JSON を整形する。直したファイルがあると commit は止まるので、`git add` して commit し直す。

## 🚀 コマンド

よく使うコマンドを、次の表に挙げる。

| 対象 | コマンド |
| --- | --- |
| 道具を入れ、hook を入れる | `make setup` |
| Xcode でワークスペースを開く | `make open` |
| ブランチのワークツリーを Xcode で開く | `make open BRANCH=feat/...` |
| 変更の確認（文書・JSON・筋書きの一覧・書き方と設計と並び・余白・iOS の警告・両 OS のテストとビルド。出力は成否と失敗の箇所だけ） | `make verify` |
| 文書の一致と書き方、JSON の整形、テストと筋書きの一覧の一致を確かめる（文書だけの変更） | `make verify-docs` |
| 筋書きの一覧の、区分ごとの件数と違いの一覧 | `make scenarios` |
| iOS のビルド（シミュレーター） | `make build` |
| テストのコンパイルだけ（走らせない） | `make test-build` |
| テスト（`ios/Kakeibot.xctestplan`、シミュレーター。出力は `.build/test.log` にも残る） | `make test` |
| 端末の中のモデルの正しさ（声の入力・一手の理由・総評）。`make test` では走らず、合格の数と文を出す | `make test-model` |
| 画面の部品を PNG に描く（下の注） | `make snapshot SNAPSHOT=widget` |
| Android のビルド（デバッグの APK） | `make android-build` |
| Android の Core・Store・画面のモデルのテスト | `make android-test` |
| Swift の並びの直しと、Swift・Kotlin・JSON の整形 | `make format` |
| ライセンスの一覧を作り直す（部品やフォントを足したとき） | `make licenses` |

`make snapshot` は claude-config の `ui-snapshot` を使う。セットは `.claude/snapshots/` の下の名前で、出力は `.build/snapshots/<セット>/` に出る。

## 📱 画面を直接開く

DEBUG のビルドは、起動の引数 `-open` で設定の画面を直接開く。`settings` なら設定のシートを、`SetupItem` の名前（`homeSections` など）ならその画面を開く。

```sh
xcrun simctl launch booted com.yossibank.kakeibot -open homeSections
```

## 🧪 申請の前に実機で回る

App Store に送る前に、TestFlight のビルドを実機に入れて、キーボードを出す画面を回る。各画面で入力欄を押し、固まらないこととキーボードの上に欄が見えることを確かめる。

- [ ] 入力シートのメモと品目の名前
- [ ] カテゴリの編集の名前とタグ
- [ ] テンプレートの編集の名前とメモ
- [ ] 口座・固定費・ポイントの規則・テーマ・目標の編集
- [ ] ホームのテンプレートの棚、記録の検索、アイコンの文字

> [!IMPORTANT]
> シミュレーターで入力の画面を確かめる時は、画面のキーボードを出す。DeviceHub の「Device → Keyboard」を開く。「Toggle Software Keyboard」を押す。
