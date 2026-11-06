# Android の構成

> [!NOTE]
> Android のモジュールと、ビルドの設定が分かる。
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
| `:store` | Room の DB。Android に頼らない JVM のモジュールで、テストは JVM の SQLite で走る |
| `:app` | Jetpack Compose のアプリ |

`:core` は、iOS の Core のファイルと 1 対 1 に対応させる。レシートの読み取りは Android に無い。`Concepts/Receipt/` は、書き出しが使う `ItemName` だけを移す。

| iOS | Android |
| --- | --- |
| `Core/Concepts/<概念>/X.swift` | `core/concepts/<概念>/X.kt`。概念の名前は小文字にする |
| `Core/Shared/X.swift` | `core/shared/X.kt` |
| `Type+Topic.swift` | `TypeTopic.kt`。拡張関数で書く |
| `Tests/CoreTests/.../XTests.swift` | `src/test/.../XTest.kt`。テストの補助は `support/` に置く |

型・プロパティ・関数の名前は iOS と同じにする。Kotlin で使えない名前だけ、次のように変える。

| 場面 | 書き方 |
| --- | --- |
| 失敗しうる `init?` | companion の `parse(text)`、または `of(...)` |
| 関連値のある enum | sealed interface。case は PascalCase |
| `name` など Kotlin の予約された名前 | 別の名前にし、rawValue は iOS のまま |
| `DraftProblem` を投げる | `DraftProblemException` |
| 金額の和と、和を返す戻り値 | `Long` |
| 1 件の金額 | `Int`。調整の額（`Adjustment.amount`）だけは `Long` |

`:store` も、iOS の Store のファイルと 1 対 1 に対応させる。同期は Android に無いので、`Store/Sync/` は移さない。マイグレーションは iOS の最新の形から始めるので、`Store/Migrations/` も移さない。

| iOS | Android |
| --- | --- |
| `Store/<フォルダ>/<中のフォルダ>/X.swift` | `store/<フォルダ>/<中のフォルダ>/X.kt`。フォルダの名前は小文字にする |
| Core の型をそのまま表の行にする | 表ごとの `XRecord`（`@Entity`）と、Core の型との変換を `records/rows/` に置く |
| `AppDatabase` の拡張 | `AppDatabase` の拡張関数（suspend） |
| 変化を見張る `ValueObservation`（`xxxUpdates()`） | `Flow` を返す拡張関数。読む表の変化を `InvalidationTracker` で受け、読み直す |
| `removeDuplicates()` | `distinctUntilChanged()` |
| 失敗を表す enum（`XError`）を投げる | 同じ名前の enum と、それを持つ `XException` |

表の形は、`store/src/test/resources/ios-schema.json` と比べて確かめる。このファイルは iOS の DB から書き出したものである。Room で同じに書けないものは、次のように守る。

| iOS | Android |
| --- | --- |
| CHECK 制約 | 表を作るときに足すトリガー |
| WHERE 付きの一意インデックス | 表を作るときに足すトリガー |
| BOOLEAN の列 | INTEGER の列。入る値は 0 と 1 で同じ |

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

`make android-test` は `:core` と `:store` のテストを走らせる。`make android-build` はデバッグの APK を作る。どちらも `make verify` に含まれる。

JDK と SDK の場所は、Makefile の次の変数で変えられる。

| 場所 | 変数 |
| --- | --- |
| JDK | `ANDROID_JAVA_HOME` |
| SDK | `ANDROID_HOME` |
