# fixtures の形式

> [!NOTE]
> Core の計算と画面の文を、iOS と Android で同じ結果にそろえる fixtures がある。
> その JSON の形式が分かる。
> 置き場所とファイル名の付け方は、[architecture-naming の「名前の決まり」](../docs/architecture-naming.md#-名前の決まり)にある。

## 📏 共通の決まり

どの fixtures も、次の決まりで書く。

| 決まり | 中身 |
| --- | --- |
| 整形 | `jq --indent 2 .` の出力の形。オブジェクトと配列を 1 行に畳まない |
| キー | camelCase |
| 日付・月・日時 | [data.md](../docs/data.md) と同じ書き方 |
| 判定の fixtures | `description`・`valid`・`invalid` を持つオブジェクト。`valid` は受け付け、`invalid` は受け付けない |
| 計算の fixtures | `description` と `cases` を持つオブジェクト。`cases` の 1 つが 1 つのテストになり、各ケースは最初に `summary` を持つ |
| 空の値や取りうる値 | 意味は `description` に書く |
| 請求期間の fixtures | `recurring/card-bill-period.json` の期間は、続く回と隙間なく重ならない。締め日と引き落とし日が 28〜31 日の組でも同じで、テストが fixtures を使わずに月を並べて確かめる |
| 書き出しの見本 | `export/export-v1.json` は、読み込んで書き出すと同じ JSON になる。DB に入れて読み出しても同じになる |
| 書き出しのキー | `export/export-v1.json` は、すべての表とすべての項目のキーを持つ。書き出しのキーの正解になる |
| 表計算の見本 | `export/export-v1.csv` は、JSON の見本の記録を表計算用に書き出した結果である。形は [export-format.md](export-format.md) にある |
| 設定の行の見本 | `export/export-v1-setting.json` は、`settings` の行の判定である |
| `voice/voice-reading.json` | `today`・`categories`・`wallets` は全ケースで使う。`modelCategory`・`modelWallet` は精度を測る時だけ使う |

## 🖥️ 画面の文の fixtures

同じ入力から同じ文字を出す画面の文も、fixtures でそろえる。読むのは、画面のモデルのテストである。

| 対象 | 場所 |
| --- | --- |
| iOS | `FeaturesTests` の `Support/FeaturesFixture.swift` |
| Android | `:featuremodels` のテストの `support/ModelFixture.kt` |

文の fixtures は、次のとおりである。どれも計算の fixtures の形で書き、出るはずの文字をそのまま持つ。

| ファイル | 中身 |
| --- | --- |
| `date/period-text-day.json` | 今日と違う年の日付にだけ年を付ける、日付の文 |
| `date/period-text-range.json` | 今日と違う年の日付にだけ年を付ける、期間の文 |
| `entry/entry-date-text.json` | 入力の画面の日付の文。`text` は曜日を添えた文、`short` は短い文 |
| `review/review-share-text.json` | 振り返りの内訳の割合の文。出さない行は `null` |
| `review/review-balance-text.json` | 収支の見出しと、符号を付けた金額の文 |

載せるのは、入力の値だけで文字が決まる関数である。DB や画面の状態が要る文は、もう一方の OS のテストを移植してそろえる。
