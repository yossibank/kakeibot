# 構成

> [!NOTE]
> kakeibot の今の形のうち、共通の iOS の構成から外れた点と、kakeibot だけの事実が分かる。
> 共通の形は [claude-config の architecture-ios](https://github.com/yossibank/claude-config/blob/main/docs/architecture-ios.md) にある。
> 手元の置き場所は、claude-config の `docs/architecture-ios.md` である。

## 🛠️ 使う技術

iOS の言語は Swift 6 で、ほかの技術は共通の形と同じである。画面と保存を選んだ理由は、decisions の[画面の作り](decisions/ios.md#画面の作り)と [DB](decisions/storage.md#db) にある。Android の技術は [architecture-android](architecture-android.md) にある。

両 OS の分け方とそろえ方は、[decisions/build.md の「共通化」](decisions/build.md#共通化)にある。

## 📂 リポジトリ

共通の木に、次のものを足している。

| パス | 中身 |
| --- | --- |
| `android/` | Android の Gradle のプロジェクト。中身は [architecture-android](architecture-android.md) にある |
| `scripts/docs-check.py` | 文書と実物の一致を確かめ、`make verify-docs` で走る。リンク先とその見出し、Makefile の入口、[architecture-packages](architecture-packages.md) の木を見る |
| `scripts/docs-check.py` の fixtures | fixtures の `description` と `summary` も見る |
| `scripts/docs-check.py` のテストプラン | `Package.swift` のテストのターゲットと、テストプランの中身が一致するかも見る |
| `scripts/spacing-check.py` | 余白・間隔・角の丸みの数値が 4 の倍数かを確かめ、`make verify` で走る。2 以下と、式の中の値は見ない |
| `scripts/json-format.sh` | `spec/fixtures/` と `store/` の JSON を整形する。`make format` と pre-commit で直し、`make verify-docs` で確かめる |
| claude-config の `hooks/docs-check.py`・`swift-style-check.py` | 書き方の決まりを確かめる。`.md` は `make verify-docs`、`.swift` は `make verify` で全部にかける |
| `spec/` | `export-format.md`、`fixtures.md`、`fixtures/` |
| `spec/fixtures/` | フォルダ名は、Core のフォルダ名の小文字にそろえる |
| `.claude/rules/` | spec の文書の役割 |
| `.claude/snapshots/` | `ui-snapshot` で描くセット。名前は描く場所（`tabs-`・`entry-`・`settings-`・`components`・`widget`・`store`）で始める |
| `scripts/snapshot-scroll.py` | セットの `patch.py` から呼ぶ。スクロールを伸ばして全体を描けるようにし、ガラスの効果を背景に変える |
| `.claude/snapshots/store/` | `store/screenshots/raw/` の画面に文言を重ね、ストアのスクリーンショットを描く |
| `store/ja/`・`en-US/`・`app-id.txt` | App Store の掲載情報と ID |
| `store/screenshots/` | ストアに出す画像。大きさごとのフォルダに置き、元の画面は `raw/` |

## 📱 ios

ターゲットと ID は、共通の形の `<App>` を `Kakeibot` にしたものである。ほかに、次のものを持つ。

| 項目 | アプリ | ウィジェット |
| --- | --- | --- |
| アプリアイコン | Icon Composer の `AppIcon.icon`（ホワイト） | |
| アイコンの色違い | 設定で選べる色違いは、同じフォルダの `AppIcon-<色>.icon` | |
| アイコンの見本 | `Assets.xcassets` の `AppIconYen`・`AppIconDial`。設定の見本に描く、アイコンと同じ絵の写し | |
| 同梱のフォント | `Kakeibot/Fonts` の TTF と、そのライセンスの文。Info.plist の `UIAppFonts` で読む | アプリのものを `WidgetFonts` で読む |
| Pro の商品 | ID は `com.yossibank.kakeibot.pro`（買い切り、ファミリー共有あり）。手元で試す設定は `ios/Kakeibot.storekit` | |
| カメラ | 撮る許可の文は、ビルド設定の `INFOPLIST_KEY_NSCameraUsageDescription` に置く | |
| 共有の受け入れ | Info.plist の `CKSharingSupported`。AppFeature の `AppDelegate` が、シーンの delegate を差し替えて共有のリンクを受け取る | |

`license_plist.yml` には、同梱のフォントと配布元のライセンスを手で足す。

### 署名

| 項目 | 状態 |
| --- | --- |
| チーム | `6WHPY5MQSB`（Apple Developer Program に加入済み） |
| 登録済みの端末 | 自分の iPhone 1 台 |
| 開発用の証明書 | 2027-01-25 まで |
| プロファイル | 2027-10-10 まで |
| 配布用の証明書 | Archive のときに Xcode がクラウドで管理するものを使う |

## 📦 パッケージ

2 つのパッケージの依存の向きと、フォルダごとの中身は、[architecture-packages](architecture-packages.md) にある。

## 🧪 テスト

テストの形は、共通の形に `SyncTests` と `AppWidgetTests` を足したものである。Core のテストは、fixtures を全部通す。

テストの補助は、使う範囲で置き場所を分ける。

| 使う範囲 | 置き場所 |
| --- | --- |
| 1 つのテストターゲット | そのターゲットの直下の `Support/`。例は `StoreTests/Support/`・`FeaturesTests/Support/` |
| 複数のテストターゲット | `Tests/TestSupport/` のターゲット |
| 1 つのテストの型 | その型の `+Setup.swift` か、同じファイル |

テストのフォルダは、共通の形の「名前の決まり」でソースにそろえる。`Shared` のテストを子フォルダに分けないことのほかに、次のものが外れる。

| テスト | 置き場所 |
| --- | --- |
| `Store/Queries`・`Store/Writes` | `Methods/`・`Types/` に分けない |
| `Store/Sync` | `Share/`・`Change/` に分ける |
| `TestSupport` のテスト | `TestSupport` にテストのターゲットが無いので、`FeaturesTests/Shared/` に置く |
| `Notifications` のテスト | テストのターゲットが無いので、`AppFeatureTests/Notifications/` に置く |
