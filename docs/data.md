# データ

## 表の関係

```mermaid
erDiagram
    icon ||--o{ wallet : "icon_id"
    icon ||--o{ category : "icon_id"
    icon ||--o{ reward_rule : "icon_id"
    icon ||--o{ calendar_stamp : "icon_id"
    wallet ||--o{ entry : "wallet_id・to_wallet_id"
    category |o--o{ entry : "category_id"
    recurring |o--o{ entry : "recurring_id"
    wallet ||--o{ recurring : "wallet_id・to_wallet_id"
    category |o--o{ recurring : "category_id"
    category |o--o{ budget : "category_id"
    reward_rule ||--o{ reward_log : "rule_id"
    entry |o--o| reward_goal : "entry_id"
```

`no_spend_day`・`theme`・`setting` はほかの表を参照しない（`setting` の `theme_id` は値として持つ）。

## 共通の決まり

> [!IMPORTANT]
> - 金額は整数（円）。小数の型を使わない
> - 記録の日付は `YYYY-MM-DD` の文字列。時刻と時差を含めない

| 決まり | 理由 |
| --- | --- |
| ID は UUID（文字列） | 書き出したデータを別の端末で読み込んでも ID がぶつからない |
| 通貨の列は持たない | 円だけを扱う |
| 月は `YYYY-MM`。呼び方は [decisions.md](decisions.md) の「期間の呼び方」 | 給料日 25 日なら 1/25〜2/24 が `2026-02` |
| 日時は UTC の ISO 8601 | 書き出しと記録忘れの判定に使う |
| 財布・カテゴリは消さずに `archived_at` でしまう | 過去の記録が参照している |
| 残高・貯金箱の残高は保存せず、記録から計算する | 二重に持つとずれる |

## 表

### icon

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| emoji | TEXT | 空でもよい |
| text | TEXT | 3 文字まで。emoji と text のどちらかは必須 |
| color | TEXT | `#RRGGBB` |
| created_at / updated_at | TEXT | |

### wallet

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| name | TEXT | |
| kind | TEXT | `cash` `bank` `card` `emoney` `point` |
| icon_id | TEXT | |
| initial_balance | INTEGER | カードはマイナスでもよい |
| sort_order | INTEGER | |
| archived_at | TEXT | |
| created_at / updated_at | TEXT | |

### category

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| kind | TEXT | `expense` `income` |
| name | TEXT | |
| icon_id | TEXT | |
| sort_order | INTEGER | |
| archived_at | TEXT | |
| created_at / updated_at | TEXT | |

### entry

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| type | TEXT | `expense` `income` `transfer` |
| amount | INTEGER | 1 以上 |
| date | TEXT | |
| category_id | TEXT | 振替は空、それ以外は必須 |
| wallet_id | TEXT | 振替では出す側 |
| to_wallet_id | TEXT | 振替だけ。wallet_id と別 |
| memo | TEXT | |
| recurring_id | TEXT | 固定費から作った記録 |
| recurring_date | TEXT | どの回の分か |
| created_at / updated_at | TEXT | |

`(recurring_id, recurring_date)` は重複禁止。支出を記録した日の `no_spend_day` は消す。

### budget

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| category_id | TEXT | 空なら月全体 |
| from_month | TEXT | この月から有効 |
| amount | INTEGER | 空ならこの月から予算なし |

ある月の予算は、`from_month` がその月以前でいちばん新しい行。`(category_id, from_month)` は重複禁止（月全体は部分インデックスで防ぐ）。

### recurring

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| type / amount / category_id / wallet_id / to_wallet_id / memo | | entry と同じ |
| frequency | TEXT | `monthly` `yearly` |
| month | INTEGER | yearly だけ |
| day | INTEGER | 1〜31。月末を超えたらその月の最終日 |
| start_date / end_date | TEXT | end_date は空でもよい |
| remind_days_before | INTEGER | 空なら知らせない |
| generated_until | TEXT | どの日まで記録を作ったか |
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
| amount | INTEGER | その時点の額を写す |
| created_at | TEXT | |

`(rule_id, date)` は重複禁止。

### reward_goal

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| name | TEXT | |
| target_amount | INTEGER | |
| purchased_at | TEXT | |
| entry_id | TEXT | 買ったときの記録 |
| created_at / updated_at | TEXT | |

貯金箱の残高 ＝ reward_log の合計 − 買った目標の target_amount の合計。

### calendar_stamp

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| date | TEXT | |
| icon_id | TEXT | |
| created_at | TEXT | |

1 日に置ける数は未決。

### no_spend_day

| 列 | 型 | 補足 |
| --- | --- | --- |
| date | TEXT | 主キー |
| created_at | TEXT | |

### theme

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| name | TEXT | |
| background / surface / text_primary / text_secondary / accent / expense / income | TEXT | `#RRGGBB`。色の数は未決 |
| corner_radius | INTEGER | |
| font_id | TEXT | 同梱フォントから選ぶ |
| is_builtin | INTEGER | |
| created_at / updated_at | TEXT | |

### setting

| key | 値 |
| --- | --- |
| month_start_day | 1〜31 |
| week_start | `monday` など |
| reminder_time | `HH:mm`。空なら知らせない |
| character_id | 同梱キャラクターの ID |
| character_name | |
| theme_id | |
| onboarding_completed | `true` `false` |

列は `key`（TEXT、主キー）と `value`（TEXT）の 2 つ。

## よく使う組み合わせ

表は持たない。直近 60 日の記録を「種類・カテゴリ・財布・金額」でまとめ、回数の多い順に 6 つ出す。日数と件数は未決。

## 表の形の変更

| | 方式 |
| --- | --- |
| iOS | GRDB の `DatabaseMigrator` |
| Android | Room の移行（iOS の最新の形から始める） |
| テスト | 古い版の DB から最新の形まで移せることを確かめる |
