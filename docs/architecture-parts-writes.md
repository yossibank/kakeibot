# 書き込みの共通の関数

> [!NOTE]
> 保存・並べ替え・非表示を、表ごとに書かずに呼ぶ関数と型が分かる。
> 画面とモデルの部品は [architecture-parts](architecture-parts.md) にある。表の形は [data](data.md) にある。

## 🗄️ 書き込みの共通の関数

保存・並べ替え・非表示は、表ごとの名前の関数を持たず、次の関数に表の型を渡して呼ぶ。

| 仕組み | 使いどころ | 置き場所 |
| --- | --- | --- |
| `AppDatabase.save(_:editing:at:)` | アイコン付きの 1 件（口座・カテゴリ・ごほうびのルール・棚のアイコン）の保存。新規と編集を 1 つにし、下書きの型ごとに 1 つずつある | `Store/Writes/Methods/AppDatabase+IconBacked.swift` |
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
| `IconHoldingDraft`（Kotlin） | `icon` と `problems` を持つ下書きの、`IconBackedDraft` の既定の処理 | `core/shared/` |
| `InsertableDao`・`UpdatableDao` | Room の DAO の insert と update。`@Query` は表ごとの DAO に残す | `store/records/protocols/` |
