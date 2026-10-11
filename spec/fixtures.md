# fixtures の形式

Core の計算を iOS と Android で同じ結果にそろえる、fixtures の JSON の形式を書く。置き場所とファイル名の付け方は、[architecture.md の「名前の決まり」](../docs/architecture.md#名前の決まり)にある。

## 共通の決まり

どの fixtures も、次の決まりで書く。

| 決まり | 中身 |
| --- | --- |
| キー | camelCase |
| 日付・月・日時 | [data.md](../docs/data.md) と同じ書き方 |
| 判定の fixtures | `valid` と `invalid` の 2 つの配列を持つオブジェクト。`valid` は受け付け、`invalid` は受け付けない |
| 計算の fixtures | 入力と期待値を並べたオブジェクトの配列。1 つのオブジェクトが 1 つのテストになる |

## date

`spec/fixtures/date` のファイルは、次の表のとおりである。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `local-date-instant.json` | 時刻と時差から、その場所の日付を出す | `instant`、`timeZone`（IANA の名前）、`date` |
| `local-date-text.json` | 日付の文字列の判定 | `valid`、`invalid`（文字列） |
| `local-date-week.json` | 日付を含む週の範囲 | `weekStart`（`monday`〜`sunday`）、`date`、`start`、`end` |
| `month-start-day.json` | 月の始まりの日の範囲 | `valid`、`invalid`（整数） |
| `year-month-period.json` | 月の始まりごとの、その月の期間 | `monthStartDay`、`month`、`start`、`end` |
| `year-month-text.json` | 月の文字列の判定 | `valid`、`invalid`（文字列） |

`year-month-period.json` では、期間の範囲のほかに日付から月への向きも試す。`start` と `end` はその月に入り、`start` の前日と `end` の翌日は前後の月に入る。

## export

`spec/fixtures/export` のファイルは、次の表のとおりである。形式は [export-format.md](export-format.md) にある。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `export-v1.json` | 読み込んで書き出すと同じ JSON になる。DB に入れて読み出しても同じになる | 書き出しの JSON そのもの |
| `export-v1-header.json` | 読み込める `format` と `version` の判定 | `valid`、`invalid`（`format` と `version` のオブジェクト） |
