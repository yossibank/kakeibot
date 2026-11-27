# 名前と置き場所

> [!NOTE]
> フォルダとファイルの名前の決まりと、1 つの概念のファイルを層ごとにどこへ置くかが分かる。
> フォルダの今の形は [architecture-packages](architecture-packages.md) にある。

## 📏 名前の決まり

共通の決まりは、claude-config の `docs/app/ios-naming.md` にある。Swift のファイルは `dotclaude/rules/swift-core.md` に従う。ここには、次の決まりを足す。

| 対象 | 決まり |
| --- | --- |
| Migrations | ファイルと型は、3 桁の通し番号で付ける。複数の番号から呼ぶ固定の SQL は `Migration<役割>` に置く |
| fixtures | `Core/Concepts/` のフォルダ名を小文字にして置く |
| `Features/Screens/Settings/` | 子フォルダが 20 を超えたら、下の表の領域の子フォルダでまとめる |
| 設定の一覧の画面 | 型は `<単数>ListModel`・`<単数>ListView`・`<単数>Board` にする |
| `Features/Shared/SettingsParts/` | ファイルの頭に `Settings` を付ける。Core の型の拡張（`<型>+<役割>`）は除く |
| `AppWidget/Widgets/` | コントロールの `kind` の文字列は、フォルダを移しても変えない |
| DesignSystem の題材のフォルダ | `Budget/`・`Date/`・`Entry/`・`Tag/`・`Template/` |
| お知らせの版の中身 | `WhatsNew/Model/` の `WhatsNewRelease+V<版>.swift` に 1 版ずつ置く。版の `.` は `_` にする |

設定の画面をまとめる時は、次の領域に分ける。入口の `Menu/` は、まとめずに残す。

| 画面のフォルダ | 領域 |
| --- | --- |
| `Budgets/` | `Book/` |
| `Categories/` | `Book/` |
| `MonthStartDay/` | `Book/` |
| `Recurring/` | `Book/` |
| `RewardRules/` | `Book/` |
| `Stamps/` | `Book/` |
| `Templates/` | `Book/` |
| `Wallets/` | `Book/` |
| `AppIcons/` | `Look/` |
| `HomeSections/` | `Look/` |
| `LaunchScreen/` | `Look/` |
| `Themes/` | `Look/` |
| `ThemeStyle/` | `Look/` |
| `WidgetGuide/` | `Look/` |
| `Backup/` | `Data/` |
| `Reminder/` | `Data/` |
| `Sync/` | `Data/` |

画面の組み立てと通知とウィジェットの方式は、[architecture-screens](architecture-screens.md) にある。

## 🏷️ 名前の付け方

上の表で決まらない名前は、次の決まりで付ける。

### 拡張のファイル

拡張のファイル（`<型>+<役割>.swift`）は、`<型>` と `<役割>` を次の決まりで付ける。

`<型>` は、次のとおりに書く。

| 拡張する型 | 書き方 | 例 |
| --- | --- | --- |
| 入れ子の型 | 親から `.` を抜いてつなげる。親は省かない | `AppDatabaseWalletWriteError+Message` |
| 標準の型 | 型引数を絞っても、標準の型の名前のまま書く | `ClosedRange<LocalDate>` は `ClosedRange+Weeks` |

`<役割>` の語は、足すものでそろえる。

| 役割の語 | 足すもの |
| --- | --- |
| `+Title` | 選ぶ画面に並べる題（`title`） |
| `+Name` | 文や見出しに入れる呼び名（`name`・`shortName`・`displayName`） |
| `+Message` | 知らせとエラーの文（`message`・`troubleMessage`） |
| `+Text` | 値を文字にしたもの（金額・割合・日付の入った文） |
| `+Values` | 画面の部品の寸法・色と、表示用の値の計算。例は `EntrySlip+Values`・`TagLine+Values` |
| `+Actions` | 画面の操作の関数。複数形で書く |
| `+Sheets` | 画面から開くシートの種類と、その振り分け。複数形で書く |
| `+Stored` | データベースに保存した形の値から作る `init` |
| `+HomeScreen` | ウィジェットの案内の、ホーム画面に置く見本。置く場所の語で `+LockScreen`・`+Control` と並べる |

型をまたぐ文言は、拡張にせず、名前空間の `enum` の `<頭>Text` に置く。例は `BillText`・`PeriodText`・`RecurringText`・`ReviewText` である。

モデルと画面の拡張は、同じ話題に同じ語を使う。資産のタブの拡張は、`Bills`・`Outlook`・`Reward`・`Wallets` で分ける。モデルも、まとめも、画面も同じ語にする。

### 層をまたぐ語

同じ語が層で違うものを指す所は、次のとおりに読み分ける。

| 語 | 指すもの |
| --- | --- |
| `<型>+Record`・`StoreRecord` | 表の行。`Store/Records/` に置く |
| `Records`・`QuickRecord`・`WidgetRecord` | 記録（`Entry`）。画面とウィジェットの名前に使う |
| `SyncRecord` | 同期で送り受けする行 |
| `EntryCategory` | Core の型と、`Store/Writes/Methods/` の拡張の名前 |
| `Category` | 画面（`CategoryListModel`）と、読み出しの型（`CategoryList`）の名前。`Entry` を略す |

読み出しの型は、行の型と語順を入れ替えただけの名前にしない。`CalendarStamp` の読み出しは `StampBook` である。`ShelfIcon` の読み出しは `ShelfIconList` である。

### 部品の語尾

部品と値の型は、役割に合う語尾で終える。新しい型は、次の表から選ぶ。

| 語尾 | 役割 | 例 |
| --- | --- | --- |
| `View` | 押し込んで開く画面の本体 | `BudgetListView` |
| `Screen` | 同じ種類の画面で使う外枠。中身は画面から受け取る | `SettingsBoardScreen` |
| `Page` | 同じ種類の画面の全体。状態を持ち、画面ごとの設定を受け取る | `SettingsBoardPage` |
| `Spec` | 同じ種類の画面で変わる所を書くプロトコル | `SettingsBoardSpec` |
| `Board` | 設定の一覧の画面ごとの `Spec` の型。`<単数>Board`。`SettingsParts` の並びの部品（`SettingsTileBoard`・`SettingsRowBoard`）は除く | `StampBoard` |
| `Sheet` | シートで開く画面。OS の共有シートを出す型にも使う | `EntrySheet`・`SyncShareSheet` |
| `EditSheet` | 1 件を編集するシート。モデルは `EditModel` で対にする | `WalletEditSheet` |
| `Card` | 面を持つ 1 かたまり | `StampTallyCard` |
| `RowCard` | 面を持つ横長の 1 件 | `WalletRowCard` |
| `IntroCard` | 画面の上の説明カード。中身の値は `IntroContent` | `SyncIntroCard` |
| `Tile` | 格子に並べる 1 枚 | `SettingsCategoryTile` |
| `Row` | 一覧の 1 行 | `SettingsMenuRow` |
| `Drawer` | 画面の下から出す引き出しと、それを重ねるモディファイア | `SettingsDrawer`・`BudgetKeypadDrawer` |
| `Layer` | 画面に層を重ねるモディファイア | `SettingsLiftLayer` |
| `Preview` | 設定の値を当てた見本 | `ThemePreview`・`HomeSectionPreview` |
| `Choice` | 選ぶ値 | `AppIconChoice`・`SyncChoice` |
| `Option` | 画面ごとの選択肢 1 件の部品 | `LaunchScreenOption` |
| `Banner` | 画面の端に重ねて出す帯と、それを出すモディファイア | `NoticeBanner` |
| `Notice` | 知らせの値とモデル | `ErrorNotice` |
| `Note` | 部品に添える短い注記 | `SettingsEmptyNote` |
| `Scene` | お知らせの使い方のコマ | `WhatsNewScene` |

表から外れたまま残している型もある。`SettingsChoice` は値でなく、選ぶ 1 件の部品である。`EntryVoiceNotice` も値でなく、取り消しの付いた知らせの部品である。

## 🗺️ 概念ごとの置き場所

1 つの概念のファイルは、層ごとに次の場所に置く。新しい概念を足す時も、同じ形にする。

| 層 | 置き場所 | 例（テーマ） |
| --- | --- | --- |
| 型と計算 | `Core/Concepts/<概念>/` | `Theme`・`ThemePalette+Contrast` |
| 表の行 | `Store/Records/Rows/` | `Theme+Record` |
| 読み出しの型 | `Core/Concepts/<概念>/` | `StampBook`（スタンプ） |
| 読み出し | `Store/Queries/Methods/` | `AppDatabase+ThemeQuery` |
| 書き込み | `Store/Writes/Methods/` | `AppDatabase+Theme` |
| 見た目の部品 | `DesignSystem/` の種類か題材のフォルダ | `DesignSystem/Theme/` |
| 画面のモデル | `FeatureModels/Screens/<画面>/` | `Settings/Themes/` |
| 画面 | `Features/Screens/<画面>/` | `Settings/Themes/`・`Settings/ThemeStyle/` |
| 複数の画面のモデルの部品 | `FeatureModels/Shared/<役割>/` | |
| 複数の画面の部品 | `Features/Shared/<役割>/` | |
| OS の枠組みへの橋 | `AppFeature/Bridge/` の `<型>+<枠組み>` | `ProStore+StoreKit`・`SyncAccount+CloudKit` |

同期は、層の間にもう 1 段を持つ。

| 層 | 置き場所 |
| --- | --- |
| 同期の状態と、共有している口座の型 | `Core/Concepts/Sync/` |
| 送る行の記録と、受け取った行の書き込み | `Store/Sync/` |
| CKSyncEngine で送り受けする | `Sync/` |
| 画面のモデルと、iCloud のアカウント（`SyncAccount`）と参加者の型 | `FeatureModels/Screens/Settings/Sync/` |
| 画面 | `Features/Screens/Settings/Sync/` |
| CloudKit から iCloud のアカウントと参加者を読む | `AppFeature/Bridge/` |

## 🧪 テストの名前

テストのファイルと型の名前は、`rules/swift-test.md` の「テストの名前」に従う。

`StoreTests/Sync/` は、次の子フォルダに分ける。

| 子フォルダ | 入れるテスト |
| --- | --- |
| `Share/` | `SyncShare` で始まる、財布の共有 |
| `Change/` | それ以外の、送る行の記録と受け取った行の書き込み |
