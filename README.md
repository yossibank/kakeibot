# Kakeibot（カケイボット）

![iOS 18+](https://img.shields.io/badge/iOS-18%2B-000000?logo=apple)
![Android 8+](https://img.shields.io/badge/Android-8%2B-3DDC84?logo=android&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
![開発中](https://img.shields.io/badge/status-開発中-orange)

**見返すのが楽しい家計簿。** テーマと、家計簿の相棒のキャラクターを自分で作れる。広告なし、データは端末の中だけ。

> [!NOTE]
> 進み具合は [docs/roadmap.md](docs/roadmap.md) の「作る順番」にある。

## 文書

| 知りたいこと | 文書 |
| --- | --- |
| 何を作るか | [docs/overview.md](docs/overview.md) |
| どう作るか | [docs/architecture.md](docs/architecture.md) |
| データの形 | [docs/data.md](docs/data.md) |
| なぜそう決めたか | [docs/decisions.md](docs/decisions.md) |
| 何をどの順で作るか | [docs/roadmap.md](docs/roadmap.md) |
| 書き出しの形式 | [spec/export-format.md](spec/export-format.md) |
| 作業と文書の決まり | [CLAUDE.md](CLAUDE.md) |

## 準備

| 道具 | 使い道 |
| --- | --- |
| Xcode | iOS のビルド |
| [Mint](https://github.com/yonaskolb/Mint) | SwiftFormat の版をそろえる |
| [pre-commit](https://pre-commit.com/) | commit の前の確認を動かす |

```sh
mint bootstrap
pre-commit install
```

> [!NOTE]
> commit の前に pre-commit が、ステージした Swift を SwiftFormat で整形する。直したファイルがあると commit は止まるので、`git add` して commit し直す。

## コマンド

| 対象 | コマンド |
| --- | --- |
| iOS のビルド（シミュレーター） | `xcodebuild -project ios/Kakeibot.xcodeproj -scheme Kakeibot -destination 'generic/platform=iOS Simulator' build` |
| Swift の整形 | `mint run swiftformat .` |
