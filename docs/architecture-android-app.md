# Android の画面とモデル

> [!NOTE]
> Android の `:featuremodels` と `:app` の中身と、画面のモデルの書き方が分かる。
> 画面とモデルのやり取りは [architecture-android-flow](architecture-android-flow.md) にある。
> モジュールの分け方・ビルドの設定・共通の部品の置き場所は [architecture-android](architecture-android.md) にある。

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
| Features の `Deletion+Notice` の文 | `notice/DeletionNotice.kt`。削除の知らせの文を出す |
| FeatureModels の `EntryNoticeModel`・`EntryChange` | `notice/` の同じ名前のファイル。知らせは `State` の `UndoNotice` に持ち、知らせごとの秒で消す |

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
| 画面から `Input` に書く | `:app` の画面から書くと、コンパイルで止まる |
| `Output` | `input` と `state` から出す値を持つ。`derivedStateOf` はここに置き、DB と `dependencies` を使わない |
| `Dependencies` | DB・時計・`Flow`・`Context`・`CoroutineScope` のような外の口を持つ。`private class` にし、モデルの関数だけが使う |
| 画面だけが使う値 | `state` と `output` の両方から出す値は、`:app` にモデルの拡張で書く。`RecurringEditModel.detailRows` が当たる |
| 動いている間の持ち物 | 認識の部品や `Job` は、`private val` の入れ物に置く。`EntryVoiceFlow` の `Runtime` が当たり、`mutableStateOf` を使わない |
| 連動する値 | `private set` にして、`State` の関数で一緒に書き換える |
| 操作の置き場所 | 状態だけを変える操作は `State` の関数に置く。DB や `output` が要る操作は、モデルの関数に置く |
| 分けたファイル | `Output` の計算は、`EntryModelOutputText.kt` のように拡張プロパティのファイルへ出す |
| 画面からの読み方 | `model.state.x`・`model.input.x`・`model.output.x` の形で読む。モデルに転送のプロパティを足さない |
| 入力の下書き | 1 つの `data class` にまとめ、`State` の `update` で書き換える。`EntryForm`・`RecurringEditForm` が当たる |
| 下書きの決まり | 口座・カテゴリ・日付を変えた時の消し込みは、下書きの型の関数に置く |
| 保存と読み込みの失敗 | `State` の `task`（`featuremodels/shared/model/` の `ModelTask`）に通す。失敗の文は、`notices` の枠を持つモデルが `notices.error`、ほかが `errorNotice` に持つ |
| 失敗の知らせの消え方 | 押すか、出してから 6 秒たつと消える。入力を変えても、後で成功しても消さない |
| 知らせを消すまでの秒 | 失敗の知らせは `ErrorNotice` が、取り消しの知らせは `UndoNotice` が数える。画面は時間を数えない |
| 容量が足りない時 | `ModelTask` が `AppDatabase.isStorageFull` で見分ける。文は「端末の空き容量が足りません」に替える |
| 端末の呼び名 | スマホとタブレットを呼び分けず、「端末」と書く。声の入力の案内も同じ語を使う |
| 監視の失敗 | `ModelTask` の `observe` に通す。`ScreenObservation` が 1・2・4 秒あけて読み直し、読めなければ `task` の知らせに出す |
| 今の時刻 | `featuremodels/shared/model/` の `ScreenClock` を使う。`dependencies.clock` から読み、モデルで `Instant.now()` を書かない |
| 説明カードを閉じたか | `settingsparts/hint/` の `SettingsFoldInput` を、モデルの `Input` に置く。読み書きは、`SettingsFoldModel` の `loadFold`・`setFold` に通す |
| 今日の日付 | タブのモデルは `input.today`、入力のモデルは `state.today` に持つ。画面が `SideEffect` でモデルの `setToday` を呼ぶ |
| 記録の一覧の監視 | `MainView` が 1 本を共有し、`ScreenParts` で配る。モデルは `Flow<EntryList>` を `Dependencies` に持つ |
| 共有した監視の持ち主 | `featuremodels/shared/model/` の `SharedObservation` がコルーチンを持つ。`MainView` が消えると、`stop` で止める |
| 共有した監視の失敗 | `ScreenObservation.share` が、失敗を受け取る側のモデルへ渡す。元の監視は、受け取る側がいる間は読み直し続ける |
| 読み込みの段階 | `Loadable` で持つ。`task.observe` の `into` に渡すと、読めない時に `Failed` を入れる |
| 監視の回 | `MainModel` が `ObservationRound` を 1 つ持つ。`LocalObservationRound` でタブに配る |
| タブの外枠 | `features/shared/tab/` の `TabScreen`。監視・知らせの時間・失敗の画面を持つ |
| 記録の知らせ | `MainView` が `EntryNoticeModel` を持ち、タブの上に出す。`EntrySheet` が閉じる時に、結果の変更を渡す |
| 知らせの入れ替え | 記録の知らせが出ると、`MainModel` の `notices.round` を `notices.next()` で進める。タブは `TabNoticeRound` で、失敗の知らせを消す |
| タブの失敗の知らせ | `TabNoticeRound` が `LocalTabNoticeShown` を呼び、出ている記録の知らせを消す |
| 失敗の後のやり直し | モデルの `retry` が回を進める。同じ回を持つタブは、すべて監視を始め直す |
| 開いているシート | `MainModel.Sheet` のように 1 つの sealed interface にし、`Shown` で持つ |
| 入口のタブとシート | `featuremodels/screens/main/` の `MainModel` が持つ。通知やリンクの行き先は、`open` が開く |
| 行き先を開く前の待ち | シートが出ていれば閉じ、`MainModel.sheetCloseDelay` だけ待ってから開く。長さは iOS と同じ 600 ミリ秒で、`SheetLayer` が下がりきる |
| 行き先の日付 | 入力の行き先は、`MainModel.Sheet.Entry` の `date` に入れる。`EntrySheet` が `EntryModel` に渡す |
| 入口の状態の引き継ぎ | `appfeature/main/` の `rememberMainModel` が、タブとシートを保存する。保存の形は `MainModel` の `saved` と `restore` にある |
| 確認・引き出し・選んだ行 | モデルの `State` に置く。`EntryModel.Overlay`（`presented.overlay`）・`RecurringPanel` が当たる |
| 画面が書いてよい値 | `State` の値のうち、`ScreenEditable` の型か、シートなどの enum・sealed の値だけ。ほかは `private set` か `internal set` にし、画面は `State` かモデルの関数を呼ぶ |
| 表示中のもの | `featuremodels/shared/model/` の `Shown<値>` に、出している 1 つを持つ。`show`・`close`（前に出ている時だけ閉じる）・`closeAll` で変える |
| 同時に出る物 | パネルと確認のように重なって出る物は、`Shown` を 2 つ持つ。1 つに混ぜない |
| 画面の見た目の値 | 画面のファイルの `class Layout` に置く。Composable の関数で `mutableStateOf` を作らない |
