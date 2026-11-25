# 共通の部品の一覧

> [!NOTE]
> 複数の画面で使う仕組みの名前、使いどころ、置き場所が分かる。
> 全体の構成は [architecture](architecture.md)、名前の付け方は [architecture-naming](architecture-naming.md) にある。

## 🪝 プロトコル

次の `Shared/` に置くプロトコルは、すべてここに載せる。置き場所は `FeatureModels`・`Features`・`Core` の 3 つである。

| 仕組み | 使いどころ | 置き場所 |
| --- | --- | --- |
| `ScreenModel` | 画面のモデル。`NoticeHolding` の状態を持ち、DB を見張って、読めなかった時は状態の知らせに出す | `FeatureModels/Shared/Model/` |
| `NoticeHolding` | エラーの知らせを持つ、モデルの状態。状態がそれだけの時は `NoticeState` を使う | `FeatureModels/Shared/Model/` |
| `ScreenPerforming` | 画面がモデルの async の関数を呼ぶ口。`perform` が `Task` を始め、画面は `Task` を書かない | `FeatureModels/Shared/Model/` |
| `SettingSaving` | 設定の値を保存するモデル。失敗したら値を戻す | `FeatureModels/Shared/Model/` |
| `SettingsBoardModel` | 並べ替え・非表示・削除のできる、設定の一覧のモデル | `FeatureModels/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardListModel` | 一覧を DB から読み、見張るモデル。`SettingsBoardPage` に載せる画面は、これに適合させる | `FeatureModels/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardDatabaseModel` | `ScreenParts` だけで作れる一覧のモデル。`SettingsBoardSpec` の `makeModel()` の既定の実装を使える | `FeatureModels/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardState` | 一覧のモデルの状態で、並べ替え中の並び・知らせ・消した物（`removed`）・出している物（`shown`）を持つ。それだけの時は `SettingsBoardMovingState` を使う | `FeatureModels/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardInput` | 一覧のモデルの入力で、DB から読んだ一覧と、説明カード・非表示の一覧を閉じたかを持つ。それだけの時は `SettingsBoardSnapshotInput` を使う | `FeatureModels/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardOutput` | 一覧のモデルの出力。出す行・非表示の行・並べ替え中の行を出す | `FeatureModels/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardSpec` | 一覧の画面ごとの設定（題・文言・並びの形・タイル・編集画面・確認）。画面ごとに 1 つ書く | `Features/Shared/SettingsParts/Board/` |
| `SettingsFoldModel` | 説明カードと非表示の一覧を閉じたかを、DB から読み書きするモデル。値は `input` の `SettingsFoldInput` に置き、モデルは `foldStore()` だけ書く | `FeatureModels/Shared/SettingsParts/Hint/` |
| `SettingsEditSheet` | 1 件を編集する画面。モデルと、削除・非表示の受け取りだけで作れる | `Features/Shared/SettingsParts/Input/` |
| `SettingsEditInput` | 編集のモデルの入力。変わる前の値と、編集中の id を持つ | `FeatureModels/Shared/SettingsParts/Input/` |
| `SettingsEditHidingInput` | 非表示にできるものの、編集のモデルの入力。非表示かどうかも持つ | `FeatureModels/Shared/SettingsParts/Input/` |
| `SettingsEditModel` | 1 件を編集するモデル。状態と入力のまとまりを持ち、下書きと、保存できるかを出す | `FeatureModels/Shared/SettingsParts/Input/` |
| `SettingsEditRemoving` | 編集のモデルに、非表示と削除を足し、状態は `SettingsEditState` にする。`save` が `finishSave` で結果を置き、失敗の文は `hideFailedMessage` などで替える | `FeatureModels/Shared/SettingsParts/Input/` |
| `SettingsEditState` | 編集のモデルの状態で、知らせ・出している物（`SettingsEditPrompt`）・結果（`outcome`）を持つ。パネルの型は、画面ごとの `Panel` で決める | `FeatureModels/Shared/SettingsParts/Input/` |
| `NamedIconDraft` | 名前とアイコンを持つ下書き（カテゴリ・口座）。アイコンの下書きと、名前とアイコンの問題を共通にする | `Core/Shared/` |
| `WidgetFallbackEntry` | ウィジェットの項目。読めなかった時の空と、見本を返す | `AppWidget/Shared/` |
| `WidgetTimelineProvider` | ウィジェットの提供元。`timeline(at:isPreview:)` だけ書けば、残りは既定の実装を使える | `AppWidget/Shared/` |
| `Draft` | 保存前の下書き。`problems` を返し、`validate()` が最初の問題を投げる | `Core/Shared/` |

## 📱 モデルから画面へ返す型

モデルの `state` に置き、画面が変化を受ける型である。受け方は、[architecture-screens](architecture-screens.md) の「モデルから画面へ結果を返す」にある。

| 仕組み | 使いどころ | 置き場所 |
| --- | --- | --- |
| `ScreenOutcome` | 保存できた・消した、の結果を 1 つ持つ。等しさは通し番号で比べる | `FeatureModels/Shared/Model/` |
| `SettingsEditOutcome` | 編集シートの結果。保存した値・非表示にしたか・消した物・閉じるかを持つ | `FeatureModels/Shared/SettingsParts/Input/` |
| `SettingsBoardRemoved` | 設定の一覧で、非表示にした行・消した物・まとめて消した結果を持つ。取り消しの知らせに使う | `FeatureModels/Shared/SettingsParts/Board/` |
| `onOutcome` | 画面が `ScreenOutcome` の変化を受ける modifier | `Features/Shared/Model/` |
| `MainOutcomeSignal` | `MainView` が結果を受ける、見えない画面。`MainView` の `body` は、結果の値を読まずに済む | `AppFeature/Main/` |

## 🗺️ 画面の部品

| 仕組み | 使いどころ | 置き場所 |
| --- | --- | --- |
| `SettingsBoardPage` | 設定の一覧の画面の全体で、`SettingsBoardSpec` を受け取り、モデルと見張りを持つ。行き先と確認は、モデルの `shown` から読む | `Features/Shared/SettingsParts/Board/` |
| `SettingsBoardLayout` | 一覧の並びの形。`tiles`（タイル）、`swipeCards`（幅を測って置く、横に払える行）、`swipeRows`（横に払える行） | `Features/Shared/SettingsParts/Board/` |
| `SettingsConfirmation` | 行を非表示・削除する前の確認の文言。`SettingsBoardSpec` が返す | `Features/Shared/SettingsParts/Board/` |
| `SettingsBoardDestination` | 新規と編集だけの行き先。`SettingsBoardMovingState` が使い、`SettingsBoardSpec` の既定の実装がある | `FeatureModels/Shared/SettingsParts/Board/` |
| `SettingsBoardShown` | 一覧の画面が出している物。行き先・開いている行・確認（`SettingsBoardPrompt`）を持つ | `FeatureModels/Shared/SettingsParts/Board/` |
| `SettingsEditPrompt` | 編集シートが出している物。開いているパネルと、メニュー・破棄・非表示・削除の確認のどれか 1 つを持つ | `FeatureModels/Shared/SettingsParts/Input/` |
| `SettingsBoardScreen` | `SettingsBoardPage` の中で使う、設定の一覧の外枠。説明カード・タイルの並び・追加ボタンを組む | `Features/Shared/SettingsParts/Board/` |
| `PageSlideReader` | 頁めくりの入れ物。動きの値を中に持って中身に `PageSlideProxy` を渡し、画面は値を持たない | `DesignSystem/Components/Navigation/` |
| `PageSlideProxy` | 頁めくりの口。`pageSlide` と `onPageSwipe` に渡し、ボタンからは `run(forward:)` で頁を送る | `DesignSystem/Components/Navigation/` |

## 🗄️ 書き込みの共通の関数

保存・並べ替え・非表示は、表ごとの名前の関数を持たず、次の関数に表の型を渡して呼ぶ。

| 仕組み | 使いどころ | 置き場所 |
| --- | --- | --- |
| `AppDatabase.save(_:editing:at:)` | アイコン付きの 1 件（口座・ごほうびのルール・棚のアイコン）の保存。新規と編集を 1 つにする | `Store/Writes/Methods/AppDatabase+IconBacked.swift` |
| `AppDatabase.reorder(_:at:)` | 並べ替えのできる表の並び順の保存 | `Store/Writes/Methods/AppDatabase+Ordering.swift` |
| `AppDatabase.setHidden(_:isHidden:at:)` | 非表示にできる表の非表示の切り替え | `Store/Writes/Methods/AppDatabase+Ordering.swift` |
| `SortableRecord` | 並べ替えのできる表の行。見つからない時のエラーを持つ | `Store/Records/Protocols/` |
| `HidableRecord` | 非表示にできる表の行。非表示の仕方を表の行が決める | `Store/Records/Protocols/` |
| `ArchivableRecord` | `archived_at` で非表示にする表の行。`HidableRecord` の既定の実装がある | `Store/Records/Protocols/` |
| `IconBackedRecord` | アイコンを持つ表の行。アイコンが見つからない時のエラーを持つ | `Store/Records/Protocols/` |
| `IconBackedDraft` | アイコン付きの 1 件を保存できる下書き。行を作る・直す操作を持つ | `Store/Writes/Types/` |
| `save(table, …)`・`reorder(table, …)`・`setHidden(table, …)` | Android の同じ関数。表ごとの束ね（`WalletTable` など）を渡す | `store/writes/methods/` |
| `SortableTable`・`HidableTable`・`ArchivableTable`・`IconBackedTable` | Android の表の束ね。表の名前・エラー・DAO の呼び方を持つ | `store/records/protocols/` |
| `IconBackedDraft`（Kotlin） | アイコン付きの 1 件の下書き。行を作る・直す操作を持つ | `core/shared/` |
| `InsertableDao`・`UpdatableDao` | Room の DAO の insert と update。`@Query` は表ごとの DAO に残す | `store/records/protocols/` |

## 🪜 設定の一覧の画面を足す

並べ替えのできる設定の一覧は、次の順で足す。

| 順 | すること | 書く所 |
| --- | --- | --- |
| 1 | モデルを `SettingsBoardListModel` と `SettingsBoardModel` に適合させる | `<単数>ListModel` |
| 2 | 設定の型を 1 つ書き、`SettingsBoardSpec` に適合させる | `<単数>Board` |
| 3 | 画面は、`body` で `SettingsBoardPage` を返すだけにする | `<単数>ListView` |

設定の型の例は、`StampBoard` と `CategoryBoard` にある。行の画面は `WalletBoard`、合計のカードを持つ画面は `RecurringBoard` を見る。`CategoryBoard` は、支出と収入の切り替えを `header` に持つ。

## 📏 画面ごとの違いの書き方

`SettingsBoardSpec` の要素のうち、既定の実装がある所は、違う画面だけが書く。

| 違い | 書く所 | 例 |
| --- | --- | --- |
| 行の画面 | `layout` を `swipeRows` か `swipeCards` にし、`grid` を 1 列にする。`tile` は行の部品を返す | `WalletBoard`・`RecurringBoard`・`TemplateBoard` |
| 持ち上げの倍率・余白 | `liftScale`・`scrollMargin` | `WalletBoard`（1.03）・`TemplateBoard`（余白 20） |
| 一覧の上の合計のカード | `lead(in:)`。タイルの並びの前に出る | `RecurringBoard` |
| 非表示にした時の文言 | `hideMessage` | `RecurringBoard` |
| 非表示・削除の前の確認 | `hideConfirmation`・`deleteConfirmation`。無ければ確認せずに行う | `WalletBoard`（非表示は残高がある時だけ）・`RecurringBoard` |
| 文字の大きさをそろえる | `scaleID(in:)`。変わると、そろえ直す | `WalletBoard`・`RecurringBoard` |
| 編集画面 | `typealias Editor` を書き、`editModel(for:)` を 1 つ書く | 全部の `Board` |
| 種類の切り替え | `header(in:)` に `CapsulePicker` を置く。行き先の型はモデルに書き、種類を持たせる | `CategoryBoard`・`RecurringBoard`・`TemplateBoard` |
| モデルを外から渡す | `makeModel()` が、持っているモデルを返す | `RecurringBoard` |
