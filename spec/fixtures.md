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

## budget

`spec/fixtures/budget` のファイルは、次の表のとおりである。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `budget-amount.json` | ある月に使う予算。`fromMonth` がその月以前でいちばん新しい行の額 | `budgets`（`category`・`fromMonth`・`amount`）、`category`、`month`、`amount` |
| `budget-usage.json` | 予算の残りと、期間の終わりまでの 1 日あたりの額、8 割を超えたか、今日あといくら使えるか | `budget`、`spent`、`upcoming`、`today`、`periodEnd`、`remaining`、`perDay`、`isOver`、`isNearLimit`、`spentToday`、`todayRemaining` |
| `budget-pace.json` | 今のペースで使ったとき、期間の終わりに予算がいくら余るか | `budget`、`spent`、`fixedSpent`、`upcoming`、`today`、`periodStart`、`periodEnd`、`projectedLeft` |

`category` が空なら月全体の予算を、名前ならそのカテゴリの予算を表す。月全体とカテゴリの予算は混ぜない。

1 日あたりの額は、残りから `upcoming` を引き、今日から期間の終わりまでの日数（今日を含む）で割る。1 円未満は切り捨て、0 以下なら 0 にする。`upcoming` は、明日から期間の終わりまでに来る固定費の支出で、無ければ 0 とする。`isNearLimit` は、使った額が予算の 8 割以上で、超えていないときに真にする。今日あといくらは、残りに `spentToday` を足して `upcoming` を引く。0 未満なら 0 にして日数で割り、1 円未満は切り捨てる。そこから `spentToday` を引き、負の値も残す。`spentToday` は今日の支出で、無ければ 0 とする。

期間の終わりの見通しは、`spent` から `fixedSpent` を引いた額（0 未満なら 0）を、期間の始まりから今日までの日数（今日を含む）で割ったペースで出す。そのペースに明日から期間の終わりまでの日数を掛け、`spent` と `upcoming` に足した額を予算から引く。掛けてから割り、1 円未満は切り捨てる。負の値は足りない額を表す。`fixedSpent` は今の期間に記録した固定費の支出で、無ければ 0 とする。

## category

`spec/fixtures/category` のファイルは、次の表のとおりである。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `category-draft.json` | カテゴリの入力の判定で出る問題 | `name`、`mark`（`kind` が `glyph`・`emoji`・`text`、`value`）、`color`、`problems` |
| `entry-tag-draft.json` | タグの名前の判定で出る問題 | `name`、`problems` |

名前と、絵文字・文字の前後の空白は除いてから判定する。文字は 3 文字まで、色は `#RRGGBB` にする。タグの名前は 8 文字までにする。

## date

`spec/fixtures/date` のファイルは、次の表のとおりである。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `date-range-weeks.json` | 期間のカレンダーのマス目 | `weekStart`、`start`、`end`、`leading`・`trailing`（前後の空きマスの数）、`rows`（週の数） |
| `holiday-dates.json` | 1 年分の祝日と名前（振替休日・国民の休日を含む） | `year`、`holidays`（その年の祝日の `date` と `name` をすべて、日付の順に） |
| `local-date-instant.json` | 時刻と時差から、その場所の日付を出す | `instant`、`timeZone`（IANA の名前）、`date` |
| `local-date-text.json` | 日付の文字列の判定 | `valid`、`invalid`（文字列） |
| `local-date-week.json` | 日付を含む週の範囲 | `weekStart`（`monday`〜`sunday`）、`date`、`start`、`end` |
| `month-start-day.json` | 月の始まりの日の範囲 | `valid`、`invalid`（整数） |
| `year-month-period.json` | 月の始まりごとの、その月の期間 | `monthStartDay`、`month`、`start`、`end` |
| `year-month-text.json` | 月の文字列の判定 | `valid`、`invalid`（文字列） |
| `year-month-weeks.json` | カレンダーのマス目 | `weekStart`、`month`、`leading`・`trailing`（前後の空きマスの数）、`rows`（週の数） |

`year-month-period.json` では、期間の範囲のほかに日付から月への向きも試す。`start` と `end` はその月に入り、`start` の前日と `end` の翌日は前後の月に入る。

## entry

`spec/fixtures/entry` のファイルは、次の表のとおりである。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `entry-draft.json` | 入力の判定で出る問題 | `type`、`amount`、`category`・`tag`（真偽）、`toWallet`（`none`・`same`・`other`）、`problems` |
| `entry-template-draft.json` | テンプレートの判定で出る問題 | `name`、`type`、`amount`（空でもよい）、`category`・`wallet`（真偽）、`problems` |
| `amount-calculator.json` | 電卓のキーを順に押したときの金額と式。式は左から順に計算し、割り算と税込みは 1 円未満を切り捨てる | `keys`（`0`〜`9`・`00`・`del`・`ac`・`+`・`-`・`*`・`/`・`=`・`tax8`・`tax10`）、`amount`、`expression`（数と記号を空白で区切る） |
| `entry-day.json` | 記録を日ごとにまとめ、支出と収入の合計を出す | `entries`（`id`・`type`・`amount`・`date`・`createdAt`）、`days`（`date`・`expense`・`income`・`entryIds`） |
| `entry-search.json` | 検索の言葉に記録が当てはまるか | `query`、`amount`、`texts`（メモ・カテゴリ・タグ・口座の名前）、`matches` |
| `entry-search-recent.json` | 探した言葉を覚えたときの並び | `recent`、`text`、`result` |
| `entry-filter.json` | カテゴリ・口座・タグで絞り込んだときに残る記録 | `categories`、`wallets`、`tags`、`entries`（`id`・`category`・`wallet`・`toWallet`・`tag`・`date`）、`keptIds` |

`entry-day.json` の日は新しい順に並べる。同じ日の記録は `createdAt` の新しい順にし、同じ時刻なら `id` の小さい順にする。

`entry-search.json` の `query` は空白（全角も含む）で言葉に分け、すべての言葉が当てはまれば真にする。言葉は `texts` のどれかに含まれるか、`¥`・`\`・`,`・`円` を除いた数が `amount` と同じなら当てはまる。大文字と小文字、全角と半角は区別しない。言葉が無ければ真にする。

`entry-search-recent.json` は、`text` の前後の空白を除いて先頭に足し、同じ言葉は前のものを消す。5 つを超えたら古いものから消す。空なら `recent` のままにする。`entry-filter.json` は、`categories`・`wallets`・`tags` が空ならすべてを残す。`categories` を選んでいれば、そのカテゴリの記録だけを残し、カテゴリの無い記録は外す。`wallets` を選んでいれば、`wallet` か `toWallet` がそのどれかの記録だけを残す。`tags` を選んでいれば、そのタグの記録だけを残し、タグの無い記録は外す。いくつかを選んでいれば、すべてに当てはまる記録を残す。残る記録は `entry-day.json` と同じ順にする。

## export

`spec/fixtures/export` のファイルは、次の表のとおりである。形式は [export-format.md](export-format.md) にある。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `export-v1.json` | 読み込んで書き出すと同じ JSON になる。DB に入れて読み出しても同じになる | 書き出しの JSON そのもの |
| `export-v1-header.json` | 読み込める `format` と `version` の判定 | `valid`、`invalid`（`format` と `version` のオブジェクト） |
| `export-v1.csv` | `export-v1.json` の記録を表計算用に書き出した結果 | CSV そのもの |

## notification

`spec/fixtures/notification` のファイルは、次の表のとおりである。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `notification-plan.json` | 予約されているべき通知の日・時刻・見出し・本文 | `today`、`reminderTime`（空なら記録忘れを知らせない）、`recorded`（記録か支出なしの印がある日）、`recurrings`（`name`・`amount`・`frequency`・`month`・`day`・`closingDay`・`startDate`・`endDate`・`remindDaysBefore`・`shortage`）、`notifications` |

`closingDay` があれば、カードへの利用分の振替として、額を入れずに知らせる。`shortage`（`date`・`wallet`・`amount`）があれば、その日の知らせに、口座の足りない額を添える。

通知は、日・時刻・識別の順に並べる。

## recurring

`spec/fixtures/recurring` のファイルは、次の表のとおりである。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `recurring-draft.json` | 固定費の入力の判定で出る問題 | `type`、`amount`、`category`・`wallet`（入っているか）、`toWallet`（`other` か `same`。無ければ空）、`frequency`、`month`、`day`、`closingDay`（無ければ空）、`startDate`、`endDate`、`remindDaysBefore`、`problems` |
| `card-bill-period.json` | カードの引き落とし日に払う、利用分の期間 | `closingDay`、`paidOn`、`from`、`through` |
| `loan-payoff.json` | 借入を返し終える回数と最後の日 | `balance`、`today`、`repayments`（`amount`・`day`・`endDate`）、`count`、`lastDate`（返し終わらなければ空） |
| `recurring-dates.json` | 固定費の、範囲の中で記録を作る日 | `frequency`（`monthly` `yearly`）、`month`（yearly だけ）、`day`、`holidayShift`（`none` `previous` `next`。無ければ `none`）、`startDate`、`endDate`、`from`、`through`、`dates` |

月末を超える `day` は、その月の最終日にする。`holidayShift` が `none` でなければ、土日・祝日・12/31〜1/3 に当たった日を前か次の平日にずらす。`startDate` より前と `endDate` より後の日は、ずらした後の日で比べて入れない。

## review

`spec/fixtures/review` のファイルは、次の表のとおりである。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `review-period.json` | 日付を含む週・月・年の範囲と、1 つ前の範囲 | `scale`（`week` `month` `year`）、`date`、`monthStartDay`、`weekStart`、`start`、`end`、`previousStart`、`previousEnd` |
| `review-summary.json` | 範囲の中の支出と収入の合計、カテゴリと財布ごとの内訳 | `start`、`end`、`entries`（`type`・`amount`・`date`・`category`・`wallet`）、`expense`・`income`（`total`、名前ごとの `categories` と `wallets`）、`balance` |

振替は、どちらの合計にも入れない。

## setting

`spec/fixtures/setting` のファイルは、次の表のとおりである。色は `#RRGGBB` で書く。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `theme-palette-contrast.json` | 2 色のコントラスト比。小数第 2 位に丸める | `first`、`second`、`ratio` |
| `theme-palette-readable.json` | 地の色に対して読みにくい色 | `theme`（役割ごとの色）、`unreadable`（役割の名前） |
| `theme-palette-base.json` | 手で選ぶ 5 色から作る、描く色の組 | `background`、`surface`、`text`、`subtext`、`accent`、`palette`（役割ごとの色） |
| `theme-draft.json` | 手で作るテーマの判定で出る問題 | `name`、`background`、`surface`、`text`、`subtext`、`accent`、`problems` |

基準は [decisions.md の「テーマの読みやすさ」](../docs/decisions.md#テーマの読みやすさ)にある。テーマの名前は、前後の空白を除いて 12 文字までにする。

描く色の組は、地が明るいかで混ぜ方を変える。混ぜた値は、色の成分ごとに四捨五入する。

| 色 | 暗い地 | 明るい地 |
| --- | --- | --- |
| `backgroundBottom` | 地に黒を 6 割 | 地に黒を 4 分 |
| `panel` | 地に黒を 3 割 5 分 | 地に黒を 2 分 |
| `cardBottom` | カードに黒を 5 割 5 分 | カードに地を 5 割 |
| `line` | カードに文字を 1 割 2 分 | 同じ |
| `accentDeep` | 強調に黒を 3 割 5 分 | 強調に白を 3 割 5 分 |
| `accentStrong` | 強調に白を 6 割 | 強調に黒を 4 割 5 分 |
| `hint` | 控えめな文字に地を 1 割 2 分 | 同じ |`unreadable` は `accent`・`accentStrong`・`text`・`subtext`・`hint` の順に並べる。

## wallet

`spec/fixtures/wallet` のファイルは、次の表のとおりである。

| ファイル | 試すこと | 項目 |
| --- | --- | --- |
| `wallet-draft.json` | 財布の入力の判定で出る問題 | `name`、`kind`、`mark`（`category-draft.json` と同じ形）、`color`、`initialBalance`、`problems` |
| `wallet-balance.json` | 1 つの財布の、ある日までの残高 | `initialBalance`、`entries`（`type`・`amount`・`date`・`wallet`・`toWallet`）、`valuations`（`date`・`amount`・`createdAt`。無ければ空）、`through`（空ならすべて）、`balance` |

財布の名前とアイコンは、カテゴリと同じ決まりで判定する。最初の残高は、マイナスでもよい。

`wallet` と `toWallet` は、`self`（残高を出す財布）か `other`（ほかの財布）で書く。残高は、最初の残高に、収入と振替で入った額を足し、支出と振替で出した額を引く。`through` までに評価額があれば、いちばん新しい評価額から、その日より後の記録だけを足し引きする。評価額と同じ日の記録は、評価額より後に作ったものだけを足し引きする。記録と評価額に `createdAt` が無ければ、記録を先に作ったものとする。
