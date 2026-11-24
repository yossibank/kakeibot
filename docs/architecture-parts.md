# 共通の部品の一覧

> [!NOTE]
> 複数の画面で使う仕組みの名前、使いどころ、置き場所が分かる。
> 全体の構成は [architecture](architecture.md)、名前の付け方は [architecture-naming](architecture-naming.md) にある。

## 🪝 プロトコル

`Features/Shared/` と `Core/Shared/` に置くプロトコルは、すべてここに載せる。

| 仕組み | 使いどころ | 置き場所 |
| --- | --- | --- |
| `ScreenModel` | 画面のモデル。DB の見張りと、読めなかった時のエラーのバナーを共通にする | `Features/Shared/Model/` |
| `NoticeHolding` | エラーの知らせを持つ、モデルの状態。状態がそれだけの時は `NoticeState` を使う | `Features/Shared/Model/` |
| `SettingSaving` | 設定の値を保存するモデル。失敗したら値を戻す | `Features/Shared/Model/` |
| `SettingsBoardModel` | 並べ替え・非表示・削除のできる、設定の一覧のモデル | `Features/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardListModel` | 一覧を DB から読み、見張るモデル。`SettingsBoardPage` に載せる画面は、これに適合させる | `Features/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardDatabaseModel` | DB と時計だけで作れる一覧のモデル。`SettingsBoardSpec` の `makeModel()` の既定の実装を使える | `Features/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardState` | 一覧のモデルの状態で、並べ替え中の並びと知らせを持つ。それだけの時は `SettingsBoardMovingState` を使う | `Features/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardInput` | 一覧のモデルの入力で、DB から読んだ一覧を持つ。それだけの時は `SettingsBoardSnapshotInput` を使う | `Features/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardOutput` | 一覧のモデルの出力。出す行・非表示の行・並べ替え中の行を出す | `Features/Shared/SettingsParts/Board/Model/` |
| `SettingsBoardSpec` | 一覧の画面ごとの設定（題・文言・並びの形・タイル・編集画面・確認）。画面ごとに 1 つ書く | `Features/Shared/SettingsParts/Board/` |
| `SettingsEditSheet` | 1 件を編集する画面。モデルと、削除・非表示の受け取りだけで作れる | `Features/Shared/SettingsParts/Input/` |
| `SettingsEditInput` | 編集のモデルの入力。変わる前の値と、編集中の id を持つ | `Features/Shared/SettingsParts/Input/` |
| `SettingsEditHidingInput` | 非表示にできるものの、編集のモデルの入力。非表示かどうかも持つ | `Features/Shared/SettingsParts/Input/` |
| `SettingsEditModel` | 1 件を編集するモデル。状態と入力のまとまりを持ち、下書きと、保存できるかを出す | `Features/Shared/SettingsParts/Input/` |
| `SettingsEditing` | 編集の画面がモデルに頼む操作（非表示・削除）と状態 | `Features/Shared/SettingsParts/Input/` |
| `SettingsEditRemoving` | 編集のモデルに、非表示と削除を足す | `Features/Shared/SettingsParts/Input/` |
| `NamedIconDraft` | 名前とアイコンを持つ下書き（カテゴリ・口座）。アイコンの下書きと、名前とアイコンの問題を共通にする | `Core/Shared/` |
| `WidgetFallbackEntry` | ウィジェットの項目。読めなかった時の空と、見本を返す | `AppWidget/Shared/` |
| `WidgetTimelineProvider` | ウィジェットの提供元。`timeline(at:isPreview:)` だけ書けば、残りは既定の実装を使える | `AppWidget/Shared/` |
| `Draft` | 保存前の下書き。`problems` を返し、`validate()` が最初の問題を投げる | `Core/Shared/` |

## 🗺️ 画面の部品

| 仕組み | 使いどころ | 置き場所 |
| --- | --- | --- |
| `SettingsBoardPage` | 設定の一覧の画面の全体。`SettingsBoardSpec` を受け取り、状態・行き先・削除の確認・見張りを持つ | `Features/Shared/SettingsParts/Board/` |
| `SettingsBoardLayout` | 一覧の並びの形。`tiles`（タイル）、`swipeCards`（幅を測って置く、横に払える行）、`swipeRows`（横に払える行） | `Features/Shared/SettingsParts/Board/` |
| `SettingsConfirmation` | 行を非表示・削除する前の確認の文言。`SettingsBoardSpec` が返す | `Features/Shared/SettingsParts/Board/` |
| `SettingsBoardDestination` | 新規と編集だけの行き先。`SettingsBoardSpec` の既定の実装がある | `Features/Shared/SettingsParts/Board/` |
| `SettingsBoardScreen` | `SettingsBoardPage` の中で使う、設定の一覧の外枠。説明カード・タイルの並び・追加ボタンを組む | `Features/Shared/SettingsParts/Board/` |

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
| 種類の切り替え | `header(in:)` に `CapsulePicker` を置き、行き先に種類を持たせる | `CategoryBoard`・`RecurringBoard`・`TemplateBoard` |
| モデルを外から渡す | `makeModel()` が、持っているモデルを返す | `RecurringBoard` |
