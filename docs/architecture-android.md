# Android の構成

> [!NOTE]
> Android のモジュールと、共通の部品の置き場所と、ビルドの設定が分かる。
> 画面とそのモデルのモジュールは [architecture-android-app](architecture-android-app.md) にある。
> 両 OS の分け方は [architecture](architecture.md) にある。

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
| `XTests+Topic.swift`（テストを分けたもの） | `XTopicTest.kt`。話題を `Test` の前に入れ、型の名前も同じにする |
| `XTests+Topic.swift`（補助の拡張だけのもの） | `XTestTopic.kt`。例は `RecordTestSample.kt`・`CardBillRecalcWriteTestSetup.kt` |

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

`:store` は JVM と Android のターゲットを持ち、ソースをターゲットごとのフォルダに分ける。

| フォルダ | 中身 |
| --- | --- |
| `src/commonMain/` | 表・読み出し・書き込み。2 つのターゲットで同じものを使う |
| `src/jvmMain/` | パスかメモリで DB を開く `AppDatabaseOpen.kt`。テストが使う |
| `src/androidMain/` | `Context` で DB を開く `AppDatabaseOpen.kt`。アプリが使う |
| `src/jvmTest/` | テスト |

DB を開く入口だけは、Room がターゲットごとに違うので分けている。どちらも、共通の `AppDatabase.open` に Room の Builder を渡す。

`:store` も、iOS の Store のファイルと 1 対 1 に対応させる。次のものは、1 対 1 から外れる。

| 外れるもの | 中身 |
| --- | --- |
| `Store/Sync/` | 同期は Android に無いので、移さない |
| `Store/Migrations/` | iOS の最新の形から始めるので、移さない |
| 振り返りの一手と理由 | `ReviewComment`・`ReviewGoal` の行・読み出し・書き込みは、まだ移していない |
| Android だけのファイル | `database/` の `AppDatabaseChecks`・`AppDatabaseObservation`。トリガーと監視を、Room の形で足す |
| iOS だけのファイル | `AppDatabase+Interruption`。`Database/` にある |

フォルダとファイルは、次のとおりに対応させる。

| iOS | Android |
| --- | --- |
| `Store/<フォルダ>/<中のフォルダ>/X.swift` | `store/<フォルダ>/<中のフォルダ>/X.kt`。フォルダの名前は小文字にする |
| Core の型をそのまま表の行にする | 表ごとの `XRecord`（`@Entity`）と、Core の型との変換を `records/rows/` に置く |
| `AppDatabase` の拡張 | `AppDatabase` の拡張関数（suspend） |
| 変化を監視する `ValueObservation`（`xxxUpdates()`） | `Flow` を返す拡張関数。読む表の変化を `InvalidationTracker` で受け、読み直す |
| `removeDuplicates()` | `distinctUntilChanged()` |
| 失敗を表す enum（`XError`）を投げる | 同じ名前の enum と、それを持つ `XException`。記録の書き込みだけは `EntryWriteError` にする |
| 書き込みの時刻（`at:`） | 既定値を置かず、呼ぶ側が必ず渡す |

iOS で分けたファイルと変えた名前のうち、次のものは Android に移していない。

| iOS | Android の今の形 |
| --- | --- |
| `AppDatabase+EntryItemQuery`（品目の読み出し） | `writes/methods/AppDatabaseEntryItem.kt` に書き込みと一緒にある |
| `AppDatabase+ReviewRequest`（レビューのお願いの記録） | `queries/methods/AppDatabaseEntryHistory.kt` にある |
| `MonthPlan`・`SettingKey+Export` | 無い |
| `Core/Shared/` の `Draft`・`String+Trimmed`、`Icon+Mark` | 無い。各下書きが検証と空白の除去を持つ |
| `Core/Shared/NamedIconDraft` | 無い。各下書きが名前とアイコンの検証を持つ |

保存・並べ替え・非表示は、iOS と同じく汎用の関数にする。iOS は型から表を決め、Android は書き込みの束ねを引数で渡す。

| iOS | Android |
| --- | --- |
| `AppDatabase+IconBacked`・`AppDatabase+Ordering` | `writes/methods/AppDatabaseIconBacked.kt`・`AppDatabaseOrdering.kt` |
| 行の型が表の操作を持つ。`SortableRecord`・`HidableRecord` など | 書き込みの束ねが表の操作を持つ。`SortableTable`・`HidableTable` など |
| 汎用の関数に型を渡す | 汎用の関数に、`writes/types/` の束ね（`WalletTable` など）を渡す |
| `Store/Writes/Types/IconBackedDraft` | `core/shared/IconBackedDraft.kt`・`IconHoldingDraft.kt`（既定の処理） |

Android の `SortableRecord`・`ArchivableRecord` は、行の列だけを表す。iOS の同じ名前のプロトコルとは役割が違う。

表ごとの読み出し・挿入・全消しは、`records/rows/` の各ファイルにある一覧にまとめる。一覧は `walletTable` など小文字で始まる値で、型は `TableBinding` である。書き出しの読み戻しと、削除の取り消しは、この一覧を順に回す。

> [!NOTE]
> 大文字で始まる `writes/types/` の `WalletTable` などは、書き込みの束ねである。`records/rows/` の一覧とは別のものである。

表の形は、`store/src/jvmTest/resources/ios-schema.json` と比べて確かめる。このファイルは iOS の DB から書き出したものである。Room で同じに書けないものは、次のように守る。

| iOS | Android |
| --- | --- |
| CHECK 制約 | 表を作るときに足すトリガー |
| WHERE 付きの一意インデックス | 表を作るときに足すトリガー |
| BOOLEAN の列 | INTEGER の列。入る値は 0 と 1 で同じ |

`:featuremodels` と `:app` の中身は、[architecture-android-app](architecture-android-app.md) にある。

### 画面と保存の境目

`:app` の `features/` は、`:store` を import しない。**DB を開けるのは、`:featuremodels` のモデルだけである。**

| 仕組み | 中身 |
| --- | --- |
| `featuremodels/shared/model/` の `ScreenParts` | DB・時計・待ち（`ScreenWait`）・記録の一覧の監視を包んで、画面からモデルへ渡す。DB と監視は `internal` で、`:app` から読めない |
| `ScreenParts` を作る所 | `AppModel` が DB を開いた時に作り、`RootView` が `MainView` に渡す。画面は、子の画面とモデルへそのまま渡す |
| `ScreenPartsShared` | 記録の一覧の監視を 1 本にまとめた `ScreenParts` を作る。`MainView` が持ち、消える時に止める |
| `:store` の型 | 画面は名前を書かず、モデルの値と関数に通す |
| `:store` の型の別名 | 画面が名前を書く型は、`:featuremodels` に別名を置く。例は、削除の取り消しに使う `Deletion` である |
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
| 読めなかった時の表示 | `features/shared/placeholder/` の `PlaceholderLoadFailed`。記録・振り返り・資産は、`TabScreen` の `LoadFailedColumn` で画面の全体に出す |
| 記録が無い時の表示 | `features/shared/placeholder/` の `PlaceholderEmpty`。記録するボタンを付けられる |
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
