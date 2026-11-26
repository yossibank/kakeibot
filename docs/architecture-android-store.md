# Android の保存のモジュール

> [!NOTE]
> Android の `:store` のフォルダと、iOS の Store のファイルとの対応が分かる。
> モジュールの分け方は [architecture-android](architecture-android.md) にある。

## 🗄️ `:store` の対応

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
| CHECK 制約 | 表を作る時に足すトリガー |
| WHERE 付きの一意インデックス | 表を作る時に足すトリガー |
| BOOLEAN の列 | INTEGER の列。入る値は 0 と 1 で同じ |
