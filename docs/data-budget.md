# 予算・固定費・ごほうび・スタンプの表

> [!NOTE]
> 予算・固定費・ごほうび・カレンダーのスタンプを保存する表の形と決まりが分かる。
> ほかの表と共通の決まりは [data](data.md) にある。

## 🗄️ 表

表ごとに、列と型と補足を書く。

### budget

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| category_id | TEXT | 空なら月全体 |
| from_month | TEXT | この月から有効 |
| amount | INTEGER | 空ならこの月から予算なし |

ある月の予算は、`from_month` がその月以前でいちばん新しい行である。`(category_id, from_month)` は重複禁止（月全体は部分インデックスで防ぐ）。額を前の月と同じに戻したら、その月の行を消す。

月全体の予算に、次の行があるとする。

| from_month | amount |
| --- | --- |
| `2026-01` | 100000 |
| `2026-04` | 120000 |
| `2026-07` | 空 |

この時、月ごとに使う行と予算は、次の表になる。

| 月 | 使う行 | 予算 |
| --- | --- | --- |
| `2026-03` | `2026-01` | 100,000 円 |
| `2026-04` | `2026-04` | 120,000 円 |
| `2026-08` | `2026-07` | なし |

### recurring

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| type / amount / category_id / wallet_id / to_wallet_id / memo | entry と同じ | 決まりも entry と同じ |
| frequency | TEXT | `monthly` `yearly` |
| month | INTEGER | yearly だけ |
| day | INTEGER | 1〜31。月末を超えたらその月の最終日 |
| holiday_shift | TEXT | `none` `previous` `next`。休日に当たったら、そのまま・前の平日・次の平日にする |
| closing_day | INTEGER | 振替だけで、1〜31（31 は末日）。あれば、記録の額を振替先のカードの利用分にし、amount は 0 にする |
| fee | INTEGER | 振替だけで、1 以上。あれば、記録する時に手数料も記録する |
| bill_shift | INTEGER | 0〜2。テンプレートと同じ。振替では 0 |
| final_amount | INTEGER | 最後の回の額で、end_date があり決まった額の時だけ入る。空なら最後の回も amount |
| start_date / end_date | TEXT | end_date は空でもよい |
| remind_days_before | INTEGER | 空なら知らせない |
| generated_until | TEXT | どの日まで記録を作ったか |
| sort_order | INTEGER | 設定の一覧の並び |
| archived_at | TEXT | しまっている間は記録を作らない |
| created_at / updated_at | TEXT | |

### reward_rule

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| name | TEXT | 「自炊した日」 |
| amount | INTEGER | |
| icon_id | TEXT | |
| is_active | INTEGER | |
| sort_order | INTEGER | |
| created_at / updated_at | TEXT | |

### reward_log

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| rule_id | TEXT | |
| date | TEXT | |
| amount | INTEGER | その時点の額を複製して持つ |
| created_at | TEXT | |

`(rule_id, date)` は重複禁止。

### reward_goal

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| name | TEXT | |
| target_amount | INTEGER | |
| purchased_at | TEXT | |
| entry_id | TEXT | 買った時の記録。その記録を消すと空にする |
| created_at / updated_at | TEXT | |

貯金箱の残高 ＝ reward_log の合計 − 買った目標の target_amount の合計。

### calendar_stamp

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| date | TEXT | |
| icon_id | TEXT | |
| created_at | TEXT | |

date ごとに 1 つまで（date に一意の索引を付ける）。押し直すと置き換える。

### no_spend_day

| 列 | 型 | 補足 |
| --- | --- | --- |
| date | TEXT | 主キー |
| created_at | TEXT | |
