# Android の構成

> [!NOTE]
> Android のモジュールと、共通の部品の置き場所と、ビルドの設定が分かる。
> `:store` は [architecture-android-store](architecture-android-store.md) にある。
> 画面とモデルは [architecture-android-app](architecture-android-app.md)、両 OS は [architecture](architecture.md) にある。

## 🛠️ 使う技術

Android は、次の技術を使う。

| 項目 | Android |
| --- | --- |
| 言語 | Kotlin |
| 画面 | Jetpack Compose |
| 保存 | Room（SQLite）。表の形は iOS と同じ |
| ウィジェット | Glance |
| 通信 | なし |

## 📦 モジュール

モジュールは、iOS のターゲットに合わせて分ける。

| モジュール | 中身 |
| --- | --- |
| `:core` | Kotlin だけで書く Core。テストは `spec/fixtures` を読み、iOS と同じ結果を確かめる |
| `:store` | Room の DB。Kotlin Multiplatform のモジュールで、テストは JVM の SQLite で走る |
| `:featuremodels` | 画面のモデル。iOS の FeatureModels に当たり、テストは JVM で走る |
| `:app` | Jetpack Compose のアプリ。iOS の KakeibotApp の残りのターゲットを、パッケージで分ける |

`:core` は、iOS の Core のファイルと 1 対 1 に対応させる。次のものは、1 対 1 から外れる。

| 外れるもの | 中身 |
| --- | --- |
| `Concepts/Receipt/` | レシートの読み取りは Android に無い。書き出しが使う `ItemName` だけを移す |
| `Concepts/Review/` | 締めのレポートと一手はまだ移していない。集計の `ReviewKind`・`ReviewPeriod`・`ReviewSummary` だけがある |
| Android だけのファイル | `ExportJson`・`ExportV1Rows`・`InstantSerializer`・`DraftProblemException`。JSON の読み書きと例外を、Kotlin の形で足す |
| iOS だけのファイル | `Bundle+Version`・`KeyedEncodingContainer+Null`。Foundation の型の拡張である |

ファイルの名前は、次のとおりに対応させる。

| iOS | Android |
| --- | --- |
| `Core/Concepts/<概念>/X.swift` | `core/concepts/<概念>/X.kt`。概念の名前は小文字にする |
| `Core/Shared/X.swift` | `core/shared/X.kt` |
| `Type+Topic.swift` | `TypeTopic.kt`。拡張関数で書く |
| `Tests/CoreTests/.../XTests.swift` | `src/test/.../XTest.kt`。テストの補助は `support/` に置く。`:store` は `src/jvmTest/` に置く |
| テストを分けた `XTests+Topic.swift` | `XTopicTest.kt`。話題を `Test` の前に入れ、型の名前も同じにする |
| 補助の拡張だけの `XTests+Topic.swift` | `XTestTopic.kt`。例は `RecordTestSample.kt`・`CardBillRecalcWriteTestSetup.kt` |

書き出しの JSON の行は、Android だけの `ExportV1Rows.kt` に書く。表の行の変換は、題材ごとの `ExportV1Rows<題材>.kt` に分ける。

型・プロパティ・関数の名前は iOS と同じにする。Kotlin で使えない名前だけ、次のように変える。

| 場面 | 書き方 |
| --- | --- |
| 失敗しうる `init?` | companion の `parse(text)`、または `of(...)` |
| 関連値のある enum | sealed interface。case は PascalCase |
| `name` など Kotlin の予約された名前 | 別の名前にし、rawValue は iOS のまま |
| `DraftProblem` を投げる | `DraftProblemException` |
| 金額の和と、和を返す戻り値 | `Long` |
| 1 件の金額 | `Int`。調整の額（`Adjustment.amount`）だけは `Long` |

`:store` の中身は [architecture-android-store](architecture-android-store.md) にある。

`:featuremodels` と `:app` の中身は、[architecture-android-app](architecture-android-app.md) にある。

### 画面と保存の境目

`:app` の `features/` は、`:store` を import しない。**DB を開けるのは、`:featuremodels` のモデルだけである。**

| 仕組み | 中身 |
| --- | --- |
| `featuremodels/shared/model/` の `ScreenParts` | DB・時計・待ち（`ScreenWait`）・記録の一覧の監視を包んで、画面からモデルへ渡す。DB と監視は `internal` で、`:app` から読めない |
| `ScreenParts` を作る所 | `AppModel` が DB を開いた時に作り、`RootView` が `MainView` に渡す。画面は、子の画面とモデルへそのまま渡す |
| `ScreenPartsShared` | 記録の一覧の監視を 1 本にまとめた `ScreenParts` を作る。`MainView` が持ち、消える時に止める |
| `:store` の型 | 画面は名前を書かず、モデルの値と関数に通す |
| 画面が名前を書く `:store` の型 | `:featuremodels` に別名を置く。例は、削除の取り消しに使う `Deletion` である |
| `make verify` の `android-features-no-store` | `features/` の下の `:store` の import を、grep で止める |

`appfeature/` と `notifications/` は、`:store` を import してよい。`:app` の依存に `:store` を残すのは、このためである。

## 📂 部品とフォルダ

複数の画面で使う部品は、次の場所に置く。

| 部品 | 置き場所 |
| --- | --- |
| 主ボタン・丸いアイコンのボタン | `designsystem/components/button/` |
| 下からの引き出し・取り消しの通知 | `designsystem/components/modal/` の `BottomDrawer`・`UndoNotice` |
| 下からせり上がる全画面の層 | `designsystem/components/modal/` の `SheetLayer`。閉じる動きの間は、最後の中身を出す |
| 失敗の知らせ | `designsystem/components/notice/` の `NoticeBanner`。タブの画面は、題のすぐ下に出す |
| 読めなかった時の表示 | `features/shared/placeholder/` の `LoadFailedPlaceholder`。記録・振り返り・資産は、`TabScreen` の `LoadFailedColumn` で画面の全体に出す |
| 記録が無い時の表示 | `features/shared/placeholder/` の `EmptyPlaceholder`。記録するボタンを付けられる |
| 振替の経路 | `designsystem/components/entry/` の `EntryRoute`。記録の行が、タグの札と一緒に出す |
| 記録の行のメモ | `designsystem/components/entry/` の `EntryMemo`。左に線を引き、2 行を超えると押して開く |
| 横に収まらない時に並べ替える | `designsystem/components/layout/` の `HorizontalFit`。iOS の `ViewThatFits` に当たる |
| 記録の知らせ | `features/shared/notice/` の `EntryNoticeBanner`。入口と入力シートが出す |
| 1 行に収めて縮める文字 | `designsystem/components/text/` の `FittedText` |
| 横線・縦の区切り | `designsystem/components/surface/` |
| 置き文字付きの入力欄 | `designsystem/components/input/` の `PlaceholderTextField` |
| ボタンの高さなどの寸法 | `designsystem/theme/` の `Metrics` |
| 設定の画面の枠 | `features/shared/settingsparts/layout/` の `SettingsFrame` |
| 期間を前後に送る見出し | `features/shared/period/` の `PeriodStepper` |
| 通知の許可 | `features/shared/notification/`。窓口は `:featuremodels` |

画面のフォルダとファイルで、iOS と違う所は次のとおりである。

| Android | iOS との違い |
| --- | --- |
| `tabs/home/`・`tabs/assets/` | 4 つのタブを `model/`・`view/` にそろえて分ける。iOS のホームは分けていない |
| `settings/menu/SettingsMenuWeekStart.kt` | 週の始まりを選ぶ画面。iOS は、設定の入口の行の中で選ぶ |
| `settingsparts/board/SettingsUndoNotice.kt` | 非表示と削除の取り消しの知らせ。iOS は `undoNotice` と `deletionNotice` に分かれる |
| `shared/tab/TabScreen.kt` | タブの外枠。iOS の `tabScreen` は失敗の画面だけを持ち、今日と監視は `MainView` が持つ |
| `entry/parts/EntryTransferArea.kt` | 振替の欄を縦に並べる枠。iOS は `EntrySheet+Transfer` に置く |
| `tabs/records/view/RecordsDayCard.kt` | 記録の 1 日分のカード。iOS は `RecordsView+Day`・`RecordsView+DayHeader` に置く |
| `shared/observation/LocalObservationRound.kt` | 監視の回を配る。iOS は `MainModel` の `ObservationRound` が全部のタブを監視し、タブに配らない |
| `tabs/review/parts/ReviewTextColor.kt` | `ReviewText` の色。文は `:featuremodels` の `ReviewText` にあり、iOS は 1 つの型に置く |
| `RecurringPanelBody`・`SegmentSwitch`・`DeleteDialog`・`DiscardDialog` | Compose で書くために足した部品。iOS に同じ名前の型は無い |

## 🔧 設定

版は、Gradle の wrapper と `gradle/libs.versions.toml` でそろえる。

| 項目 | 値 |
| --- | --- |
| applicationId | `com.yossibank.kakeibot` |
| minSdk | 26（Android 8） |
| compileSdk・targetSdk | 36 |
| Gradle を動かす JDK | Android Studio に入っている JBR |
| Kotlin の toolchain | 17 |

## 🧪 確認

`make android-test` は `:core`・`:store`・`:featuremodels` のテストを走らせる。`make android-build` はデバッグの APK を作る。どちらも `make verify` に含まれる。

JDK と SDK の場所は、Makefile の次の変数で変えられる。

| 場所 | 変数 |
| --- | --- |
| JDK | `ANDROID_JAVA_HOME` |
| SDK | `ANDROID_HOME` |
