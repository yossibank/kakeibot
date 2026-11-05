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
| `:app` | Jetpack Compose のアプリ |

`:core` のパッケージは、iOS の `Core/Concepts/<概念>/` に当たる `core.concepts.<概念>` に置く。概念の名前は小文字にする。

## 🔧 設定

版は、Gradle の wrapper と `gradle/libs.versions.toml` でそろえる。

| 項目 | 値 |
| --- | --- |
| applicationId | `com.yossibank.kakeibot` |
| minSdk | 26（Android 8） |
| compileSdk・targetSdk | 36 |
| JDK | 17。Gradle も Kotlin の toolchain も、この版で動かす |

## 🧪 確認

`make android-test` は `:core` のテストを走らせる。`make android-build` はデバッグの APK を作る。どちらも `make verify` に含まれる。

JDK と SDK の場所は、Makefile の次の変数で変えられる。

| 場所 | 変数 |
| --- | --- |
| JDK | `ANDROID_JAVA_HOME` |
| SDK | `ANDROID_HOME` |
