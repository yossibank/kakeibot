# 名前と置き場所

> [!NOTE]
> フォルダとファイルの名前の決まりと、1 つの概念のファイルを層ごとにどこへ置くかが分かる。
> フォルダの今の形は [architecture](architecture.md) にある。

## 📏 名前の決まり

フォルダとファイルの名前は、共通の形の「名前の決まり」と `rules/swift-core.md` に従う。ほかに、次の決まりを足す。

| 対象 | 決まり |
| --- | --- |
| Migrations | ファイルと型は、3 桁の通し番号で付ける |
| fixtures | `Core/Concepts/` のフォルダ名を小文字にして置く |
| `Features/Screens/Settings/` | 子フォルダが 20 を超えたら、下の表の領域の子フォルダでまとめる |
| 設定の一覧の画面 | 型は `<単数>ListModel`・`<単数>ListView` にする |
| `Features/Shared/SettingsParts/` | ファイルの頭に `Settings` を付ける。Core の型の拡張（`<型>+<役割>`）は除く |
| `AppWidget/Intents/` | ウィジェットとコントロールの AppIntent を、すべてここに置く。頭に、使うウィジェットの名前を付ける |
| `AppWidget/Widgets/` | コントロールも、ファイルが 1 つでも、ウィジェットと同じくフォルダを分ける。コントロールの `kind` の文字列は変えない |
| `Store/Writes/Methods/`・`Store/Queries/Methods/` | `+` の後ろは、Core の型の名前のまま書く（`AppDatabase+EntryTag`） |
| `Store/Records/` | 行の型の拡張は `Rows/`、行の型が従うプロトコルは `Protocols/` に置く |

DesignSystem の `Components/` の子フォルダは、種類と題材の 2 通りがある。

| フォルダ | 入れるもの |
| --- | --- |
| 種類（`Button/`・`Modal/`・`Text/` など） | 1 つの種類の部品。題材をまたいで使う部品は、ここに置く |
| 題材（`Budget/`・`Date/`・`Entry/`・`Tag/`・`Template/`） | その題材の型を表す部品と、その型の拡張だけ |

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

テストのファイルと型は、試すものに合わせて次の名前にする。

| 試すもの | 名前 | 例 |
| --- | --- | --- |
| 1 つのソースのファイル | ソースのファイル名から `+` を抜き、`Tests` を付ける | `ThemePaletteContrastTests` |
| 1 つのソースを話題で分ける | 上の名前の `Tests` の前に話題を足す | `BudgetCarryoverTests` |
| 1 つのテストの型を分ける | `<テストの型>+<話題>.swift` | `EntryModelTests+Item` |
| `Store/Writes/` の `AppDatabase+<型>` | `<型>WriteTests` | `EntryTagWriteTests` |
| `Store/Queries/` | 返す型の名前に `Tests` を付ける | `EntryHistoryTests` |
| `Store/Sync/` | `Sync<話題>Tests` | `SyncConflictTests` |
| 同じ役割の複数のファイル | 役割の名前に `Tests` を付ける | `DatabaseValueTests`・`RecordTests` |

`StoreTests/Sync/` は、ファイルが 20 本を超えたら、次の子フォルダに分ける。

| 子フォルダ | 入れるテスト |
| --- | --- |
| `Share/` | `SyncShare` で始まる、財布の共有 |
| `Change/` | それ以外の、送る行の記録と受け取った行の書き込み |
