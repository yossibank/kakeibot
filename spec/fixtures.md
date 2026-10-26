# fixtures の形式

Core の計算を iOS と Android で同じ結果にそろえる、fixtures の JSON の形式を書く。置き場所とファイル名の付け方は、[architecture.md の「名前の決まり」](../docs/architecture.md#名前の決まり)にある。

## 共通の決まり

どの fixtures も、次の決まりで書く。

| 決まり | 中身 |
| --- | --- |
| キー | camelCase |
| 日付・月・日時 | [data.md](../docs/data.md) と同じ書き方 |
| 判定の fixtures | `description`・`valid`・`invalid` を持つオブジェクト。`valid` は受け付け、`invalid` は受け付けない |
| 計算の fixtures | `description` と `cases` を持つオブジェクト。`cases` の 1 つが 1 つのテストになり、各ケースは最初に `summary` を持つ |
| 空の値や取りうる値 | 意味は `description` に書く |
| 書き出しの見本 | `export/export-v1.json` は、読み込んで書き出すと同じ JSON になり、DB に入れて読み出しても同じになる。`export/export-v1.csv` は、その記録を表計算用に書き出した結果である。形は [export-format.md](export-format.md) にある |
