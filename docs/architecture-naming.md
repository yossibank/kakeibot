# 名前と置き場所

> [!NOTE]
> フォルダとファイルの名前の決まりと、1 つの概念のファイルを層ごとにどこへ置くかが分かる。
> フォルダの今の形は [architecture-packages](architecture-packages.md) にある。

## 📏 名前の決まり

共通の決まりは、claude-config の `docs/architecture-ios-naming.md` にある。Swift のファイルは `rules/swift-core.md` に従う。ここには、次の決まりを足す。

| 対象 | 決まり |
| --- | --- |
| Migrations | ファイルと型は、3 桁の通し番号で付ける |
| fixtures | `Core/Concepts/` のフォルダ名を小文字にして置く |
| `Features/Screens/Settings/` | 子フォルダが 20 を超えたら、下の表の領域の子フォルダでまとめる |
| 設定の一覧の画面 | 型は `<単数>ListModel`・`<単数>ListView` にする |
| `Features/Shared/SettingsParts/` | ファイルの頭に `Settings` を付ける。Core の型の拡張（`<型>+<役割>`）は除く |
| `AppWidget/Widgets/` | コントロールの `kind` の文字列は、フォルダを移しても変えない |
| DesignSystem の題材のフォルダ | `Budget/`・`Date/`・`Entry/`・`Tag/`・`Template/` |
| お知らせの版の中身 | `WhatsNew/` の `WhatsNewRelease+V<版>.swift` に 1 版ずつ置く。版の `.` は `_` にする |

設定の画面をまとめるときは、次の領域に分ける。入口の `Menu/` は、まとめずに残す。

| 領域 | 画面のフォルダ |
| --- | --- |
| `Book/` | `Budgets/`・`Categories/`・`MonthStartDay/`・`Recurring/`・`RewardRules/`・`Stamps/`・`Templates/`・`Wallets/` |
| `Look/` | `AppIcons/`・`HomeSections/`・`LaunchScreen/`・`Themes/`・`ThemeStyle/`・`WidgetGuide/` |
| `Data/` | `Backup/`・`Reminder/`・`Sync/` |

画面の組み立てと通知とウィジェットの方式は、[architecture-screens](architecture-screens.md) にある。

## 🗺️ 概念ごとの置き場所

1 つの概念のファイルは、層ごとに次の場所に置く。新しい概念を足すときも、同じ形にする。

| 層 | 置き場所 | 例（テーマ） |
| --- | --- | --- |
| 型と計算 | `Core/Concepts/<概念>/` | `Theme`・`ThemePalette+Contrast` |
| 表の行 | `Store/Records/Rows/` | `Theme+Record` |
| 読み出し | `Store/Queries/Methods/` | `AppDatabase+ThemeQuery` |
| 書き込み | `Store/Writes/Methods/` | `AppDatabase+Theme` |
| 見た目の部品 | `DesignSystem/` の種類か題材のフォルダ | `DesignSystem/Theme/` |
| 画面 | `Features/Screens/<画面>/` | `Settings/Themes/`・`Settings/ThemeStyle/` |
| 複数の画面の部品 | `Features/Shared/<役割>/` | |
| OS の枠組みへの橋 | `AppFeature/Bridge/` の `<型>+<枠組み>` | `ProStore+StoreKit`・`SyncAccount+CloudKit` |

同期は、層の間にもう 1 段を持つ。

| 層 | 置き場所 |
| --- | --- |
| 送る行の記録と、受け取った行の書き込み | `Store/Sync/` |
| CKSyncEngine で送り受けする | `Sync/` |
| 画面と、口座と参加者の型 | `Features/Screens/Settings/Sync/` |
| CloudKit から口座と参加者を読む | `AppFeature/Bridge/` |

## 🧪 テストの名前

テストのファイルと型の名前は、`rules/swift-test.md` の「テストの名前」に従う。

`StoreTests/Sync/` は、次の子フォルダに分ける。

| 子フォルダ | 入れるテスト |
| --- | --- |
| `Share/` | `SyncShare` で始まる、財布の共有 |
| `Change/` | それ以外の、送る行の記録と受け取った行の書き込み |
