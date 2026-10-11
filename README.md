# Kakeibot（カケイボット）

iOS・Android の家計簿アプリ

![iOS 18+](https://img.shields.io/badge/iOS-18%2B-000000?logo=apple&logoColor=white)
![Android 8+](https://img.shields.io/badge/Android-8%2B-3DDC84?logo=android&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0A84FF?logo=swift&logoColor=white)
![GRDB](https://img.shields.io/badge/GRDB-003B57?logo=sqlite&logoColor=white)

## 文書

知りたいことごとに、読む文書が分かれている。

| 知りたいこと | 文書 |
| --- | --- |
| 何を作るか | [docs/overview.md](docs/overview.md) |
| どう作るか | [docs/architecture.md](docs/architecture.md) |
| データの形 | [docs/data.md](docs/data.md) |
| なぜそう決めたか | [docs/decisions.md](docs/decisions.md) |
| 何をどの順で作るか | [docs/roadmap.md](docs/roadmap.md) |
| 書き出しの形式 | [spec/export-format.md](spec/export-format.md) |
| 作業と文書の決まり | [CLAUDE.md](CLAUDE.md) |
| 文書の役割 | [.claude/rules/doc-roles.md](.claude/rules/doc-roles.md) |
| 全リポジトリ共通の決まり | [claude-config](https://github.com/yossibank/claude-config) |

## 動かし方

Xcode と [Homebrew](https://brew.sh/) が要る。ほかの道具は `make setup` で入る。

| 道具 | 使い道 |
| --- | --- |
| [Mint](https://github.com/yonaskolb/Mint) | SwiftFormat の版をそろえる（`Mintfile`） |
| [pre-commit](https://pre-commit.com/) | commit の前の確認を動かす |

> [!NOTE]
> commit の前に pre-commit が、ステージした Swift を SwiftFormat で整形する。直したファイルがあると commit は止まるので、`git add` して commit し直す。

よく使うコマンドを、次の表に挙げる。

| 対象 | コマンド |
| --- | --- |
| 道具を入れ、hook を入れる | `make setup` |
| iOS のビルド（シミュレーター） | `make build` |
| Swift の整形 | `make format` |
