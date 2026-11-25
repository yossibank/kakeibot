# Android の画面とモデル

> [!NOTE]
> Android の `:featuremodels` と `:app` の中身と、画面のモデルの書き方が分かる。
> モジュールの分け方とビルドの設定は [architecture-android](architecture-android.md) にある。

## 📦 モデルのモジュール

`:featuremodels` は、画面のモデルと、モデルが使う値の型・文言を置く。フォルダは、`:app` の `features/` と同じ形にする。

| 項目 | 決まり |
| --- | --- |
| 依存 | `:core`・`:store` と、Compose の runtime だけに頼る。Compose の UI と `:app` には頼らない |
| パッケージ | `com.yossibank.kakeibot.featuremodels`。iOS の `FeatureModels/<フォルダ>/X.swift` を、`featuremodels/<フォルダ>/X.kt` に置く |
| 置く物 | Compose の UI を使わないモデル・値の型・文言。`android.speech` で声を聞く `EntryVoiceFlow` も置く |
| 置かない物 | 絵の番号（`R.drawable`）や、画面の座標を持つ型。`RecurringDetailRow`・`RecurringLift` は `:app` に残す |
| 公開 | 画面から使う物だけを public にする。`internal` の物は、`:app` から見えない |

iOS の FeatureModels は DesignSystem に頼る。Android の `designsystem` は `:app` にあり、`:featuremodels` から読めない。

そこで、モデルが使う次の物は `:featuremodels` に置く。`designsystem` も、ここから読む。

| iOS の DesignSystem | Android の `featuremodels/shared/` |
| --- | --- |
| `AmountText` の金額の文字 | `amount/AmountText.kt` の `object AmountText` と `clamped`。Composable の `AmountText` は `designsystem/components/text/` に残す |
| `Keypad` の演算の記号 | `amount/AmountCalculatorOperationSymbol.kt` |
| `FeeChoiceRow.defaultChoices` | `amount/FeeChoiceRow.kt` の `object FeeChoiceRow`。Composable は `designsystem/components/row/` に残す |
| `Weekday+Name` | `datechoice/WeekdayName.kt` |
| 無い | `notice/UndoNoticeState.kt`。取り消しの知らせの状態で、Android だけにある |
| Features の `Deletion+Notice` の文 | `notice/DeletionNotice.kt`。削除の知らせの文を出す |

## 📱 アプリのモジュール

`:app` は、iOS の残りのターゲットをパッケージにし、その下のフォルダも iOS に合わせる。

| iOS | Android |
| --- | --- |
| `AppFeature/<フォルダ>/X.swift` | `appfeature/<フォルダ>/X.kt` |
| `DesignSystem/<フォルダ>/X.swift` | `designsystem/<フォルダ>/X.kt` |
| `Features/<フォルダ>/X.swift` | `features/<フォルダ>/X.kt` |
| `Notifications/X.swift` | `notifications/X.kt`。予約・届いた通知・再起動の受け口を置く |
| `View+Topic.swift` | `ViewTopic.kt` |
| SF Symbols の絵 | `res/drawable/` の `ic_<名前>.xml` |
| アイコンの絵柄（`Icon.Glyph`） | `res/drawable/` の `ic_glyph_<名前>.xml`。Material Symbols の絵を使う |

画面の部品は、iOS と同じ名前の Composable で書く。Compose で同じに書けないものは、次のようにする。

| iOS | Android |
| --- | --- |
| `@Observable` のモデル | Compose の状態を持つクラス。`AppModel` だけは ViewModel にする |
| `@Environment` の値 | `Local<名前>` の CompositionLocal |
| `Palette.accent` などの色 | `Palette` の Composable のプロパティ。`LocalPalette` のテーマから読む |
| フォントを付けるモディファイア | `TextStyle` を返す `displayFont`・`textFont`・`sansFont` |
| 大きさを固定したフォント | dp から直した sp。端末の文字の大きさに合わせない |
| 見た目の明暗の上書き | `PaletteScene` がテーマを配り、バーのアイコンの色を合わせる |
| ガラスの効果 | 背景の色を濃く敷く |
| 同梱のフォント | 入れない。明朝は端末の serif、ほかは端末の既定で出す |
| シート（`.sheet`） | 画面の上に、下からせり上がる全画面の層で出す。戻る操作で閉じる |

アイコンの絵柄は、すべてに Material Symbols の絵を用意している。

## 📏 モデルの決まり

画面のモデルは、次の決まりで書く。

| 対象 | 決まり |
| --- | --- |
| モデルの形 | `state`・`input`・`output` の `val` と、`private val dependencies` を持つ。使わないまとまりは書かない |
| `State` | 人の操作で変わる値と、進み具合・知らせを持つ。`mutableStateOf` は 12 個まで、Boolean は 3 個までである |
| `Input` | DB から読んだ値と、最初に渡された値を持つ。setter を `internal set` にし、モデルの関数だけが書く |
| `Input` への書き込み | `:app` の画面から書くと、コンパイルで止まる |
| `Output` | `input` と `state` から出す値を持つ。`derivedStateOf` はここに置き、DB と `dependencies` を使わない |
| `Dependencies` | DB・時計・`Flow`・`Context`・`CoroutineScope` のような外の口を持つ。`private class` にし、モデルの関数だけが使う |
| 画面だけが使う値 | `state` と `output` の両方から出す値は、`:app` にモデルの拡張で書く。`RecurringEditModel.detailRows` が当たる |
| 動いている間の持ち物 | 認識の部品や `Job` は、`private val` の入れ物に置く。`EntryVoiceFlow` の `Runtime` が当たり、`mutableStateOf` を使わない |
| 連動する値 | `private set` にして、`State` の関数で一緒に書き換える |
| 操作の置き場所 | 状態だけを変える操作は `State` の関数に置く。DB や `output` が要る操作は、モデルの関数に置く |
| 分けたファイル | `Output` の計算は、`EntryModelOutputText.kt` のように拡張プロパティのファイルへ出す |
| 画面からの読み方 | `model.state.x`・`model.input.x`・`model.output.x` の形で読む。モデルに転送のプロパティを足さない |
| 入力の下書き | 1 つの `data class` にまとめ、`State` の `update` で書き換える。`EntryForm`・`RecurringEditForm` が当たる |
| 下書きの決まり | 口座・カテゴリ・日付を変えたときの消し込みは、下書きの型の関数に置く |
| 保存と読み込みの失敗 | `featuremodels/shared/model/` の `ModelTask` に通す。失敗の文と実行中かどうかを、`State` の `task` に持つ |
| 失敗の知らせの消え方 | 押すか、出してから 6 秒たつと消える。後の成功では消さず、画面が `task.Timer()` で数える |
| 容量が足りない時 | `ModelTask` が `AppDatabase.isStorageFull` で見分ける。文は「端末の空き容量が足りません」に替える |
| 見張りの失敗 | `ModelTask` の `observe` に通す。`ScreenObservation` が 1・2・4 秒あけて読み直し、それでも読めなければ `task` に文を出す |
| 今の時刻 | `featuremodels/shared/model/` の `ScreenClock` を使う。`dependencies.clock` から読み、モデルで `Instant.now()` を書かない |
| 説明カードを閉じたか | `settingsparts/hint/` の `SettingsFoldInput` を、モデルの `Input` に置く。読み書きは、`SettingsFoldModel` の `loadFold`・`setFold` に通す |
| 今日の日付 | モデルの `state.today` に持ち、画面が `SideEffect` で入れる。`AssetsModel` だけは iOS と同じく `input.today` に持ち、画面が `setToday` で入れる |
| 記録の一覧の見張り | `MainView` が 1 本を共有し、`LocalEntryList` で配る。モデルは `Flow<EntryList>` を `Dependencies` に持つ |
| 共有した見張りの失敗 | `ScreenObservation.share` が、失敗を受け取る側のモデルへ渡す。元の見張りは、受け取る側がいる間は読み直し続ける |
| 開いているシート | `MainSheet` のように、1 つの sealed interface で持つ |

モデルのテストは `featuremodels/src/test/` に置く。`modelTest` が DB をメモリに開き、`ModelWait` が値を待つ。iOS と違う動きは `@Ignore` の理由に書く。

テストは、iOS のテストと 1 件ずつ結び付けて [scenarios](../spec/scenarios.md) の一覧に載せる。

入力の値だけで決まる画面の文は、`spec/fixtures` を読んで確かめる。読む部品は `support/ModelFixture.kt` で、iOS も同じファイルを読む。形式は [fixtures](../spec/fixtures.md) にある。

読み書きの失敗は、`support/AppDatabaseFailure.kt` で起こす。記録の一覧の失敗は、失敗する `Flow` をモデルに渡して起こす。

## 📂 部品とフォルダ

複数の画面で使う部品は、次の場所に置く。

| 部品 | 置き場所 |
| --- | --- |
| 主ボタン・丸いアイコンのボタン | `designsystem/components/button/` |
| 下からの引き出し・取り消しの通知 | `designsystem/components/modal/` の `BottomDrawer`・`UndoNotice` |
| 失敗の知らせ | `designsystem/components/notice/` の `NoticeBanner`。タブの画面は、題のすぐ下に出す |
| 1 行に収めて縮める文字 | `designsystem/components/text/` の `FittedText` |
| 横線・縦の区切り | `designsystem/components/surface/` |
| 置き文字付きの入力欄 | `designsystem/components/input/` の `PlaceholderTextField` |
| ボタンの高さなどの寸法 | `designsystem/theme/` の `Metrics` |
| 設定の画面の枠 | `features/shared/settingsparts/layout/` の `SettingsFrame` |
| 期間を前後に送る見出し | `features/shared/period/` の `PeriodStepper` |
| 通知の許可 | `features/shared/notification/` |

画面のフォルダとファイルで、iOS と違う所は次のとおりである。

| Android | iOS との違い |
| --- | --- |
| `tabs/home/`・`tabs/assets/` | 4 つのタブを `model/`・`view/` にそろえて分ける。iOS のホームは分けていない |
| `settings/menu/SettingsMenuWeekStart.kt` | 週の始まりを選ぶ画面。iOS は、設定の入口の行の中で選ぶ |
| `settingsparts/board/SettingsUndoNotice.kt` | 非表示と削除の取り消しの知らせ。iOS は `SettingsHideNotice` と、削除の知らせに分かれる |
| `tabs/review/parts/ReviewTextColor.kt` | `ReviewText` の色。文は `:featuremodels` の `ReviewText` にあり、iOS は 1 つの型に置く |
| `RecurringPanelBody`・`SegmentSwitch`・`DeleteDialog`・`DiscardDialog` | Compose で書くために足した部品。iOS に同じ名前の型は無い |
