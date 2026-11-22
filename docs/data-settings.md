# 設定とテーマと一手の理由の表

> [!NOTE]
> テーマの表・設定の表・振り返りの一手の理由と一手の表の形が分かる。
> ほかの表と共通の決まりは [data](data.md) にある。

## 🗄️ 表

表ごとに、列と型と補足を書く。

### theme

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | |
| name | TEXT | |
| background / surface / text_primary / text_secondary / accent / expense / income | TEXT | `#RRGGBB`。地・カード・文字・控えめな文字・強調と、支出・収入の色 |
| corner_radius | INTEGER | 今は使わない。角の丸みは setting の `corner_style` で選ぶ |
| font_id | TEXT | 今は使わない。字体は setting の `font_style` と `text_font_style` で選ぶ |
| is_builtin | INTEGER | |
| created_at / updated_at | TEXT | |

expense・income の列は、描画に使わない。

### setting

列は `key`（TEXT、主キー）と `value`（TEXT）の 2 つ。`key` は表では縛らず、下の表の名前だけをアプリで使う。

| key | 値 | 補足 |
| --- | --- | --- |
| month_start_day | 1〜31 | 月末を超えたらその月の最終日 |
| month_start_shift | `previous` `next` | 月の始まりが休日なら、前か次の平日にする。空ならずらさない |
| budget_carryover_from | 予算の繰越を始めた期間の月。`2026-11` の形 | 空なら繰り越さない |
| week_start | `monday`〜`sunday` | 空なら日曜 |
| reminder_time | `HH:mm` | 空なら知らせない |
| theme_id | `system`（iPhone に合わせる）か、用意したテーマの名前か、手で作った theme の id | 空なら `system`。用意したテーマの名前は `navy` などで、アプリアイコンの色違いと同じ |
| onboarding_completed | `true` `false` | |
| setup_card_closed | `true` なら、ホームの残りの設定のカードを出さない | |
| entry_opened | `true` `false` | 入力シートを一度開くと `true` にし、入力の ＋ に光を回さない |
| settings_opened | `true` `false` | 今は読み書きしない |
| launch_screen | `home`・`records`・`review`・`assets`・`entry` | 空ならホーム |
| corner_style | `square`・`small`・`standard`・`large` | 空なら `standard`。`square` は角を丸めない |
| font_style | 見出しと金額の字体。`mincho`・`gothic`・`rounded`・`handwriting`・`dot`・`pop` | 空なら `mincho` |
| text_font_style | 本文の字体。`mincho`・`gothic`・`rounded`・`handwriting`・`dot`・`pop` | 空なら `gothic` |
| text_size | 文字の大きさ。`small`・`standard`・`large` | 空なら `standard` |
| row_spacing | 記録の一覧の行の高さと上下の余白。`compact`・`standard`・`relaxed` | 空なら `standard` |
| stamp_shape | スタンプの印の形。`circle`・`rounded`・`seal`（塗らない二重の輪） | 空なら `circle`。`rounded` は corner_style に従う |
| tab_titles | 下のタブに名前を出すか。`true` `false` | 空なら `true` |
| backdrop | 画面の背景の柄。`plain`・`ruled`（ノートの罫線）・`grid` | 空なら `plain`。`washi` は `ruled` として読む |
| haptics | 押した時に振動するか。`true` `false` | 空なら `true` |
| decorations | 光の影とタブの金の輪を出すか。`true` `false` | 空なら `true` |
| entry_starts_with_amount | 今は使わない | |
| categories_by_use | 今は使わない | |
| template_order | `manual` `frequent` `category` `amount` `name` | 空なら並べた順 |
| home_sections | ホームに並べる順。`customize` `budget` `templates` `recent` `bills` `stamps` を `,` でつないだもの | 空なら `budget` `customize` `templates` `recent` の順。無いものは後ろに足し、`bills` と `stamps` は非表示にする |
| home_hidden_sections | ホームに出さないもの。書き方は home_sections と同じで、すべては非表示にしない | 空なら home_sections にあるものをすべて出す |
| records_layout | `calendar` `list` | 空ならカレンダー |
| review_scale | `week` `month` `year` | 空なら月 |
| review_kind | `expense` `income` `balance` | 空なら支出 |
| store_review_card_closed | `true` なら、振り返りのレビューの札を出さない | Android は持たない |
| store_review_opened | `true` なら、レビューのお願いを出さない | 札の「レビューを書く」を押すと `true` にする。Android は持たない |
| closed_hints | 説明を閉じた設定の画面を `,` でつないだもの | 空ならすべて出す。画面の名前は、表の下の一覧にある |
| closed_hidden_lists | 非表示の項目をたたんだ設定の画面。書き方は closed_hints と同じ | 空ならすべて開く |
| recent_searches | 記録の検索で探した言葉を、新しい順に改行でつないだもの。5 つまで | |
| widget_entry | すぐ記録のウィジェットで最後に記録した entry の id。取り消すと消す | その記録で支出なしの印を消したときは、`,` に続けてその日付（`2026-10-03`）を付ける |
| receipt_saved_count | レシートから読んで保存した記録の数 | 空なら 0。Pro でなければ 3 で止める |
| receipt_guide_hidden | `true` なら、レシートの撮り方を出さずにカメラを開く | 撮り方の「次から表示しない」に印を付けて閉じると `true` にする |
| fee_category_id | 振替の手数料に付ける category の id | |
| transfer_out_category_id | 抜けた共有の財布への振替を、支出に変えるときに付ける category の id | |
| transfer_in_category_id | 抜けた共有の財布からの振替を、収入に変えるときに付ける category の id | |
| backup_exported_at | バックアップを JSON で最後に書き出した日時。ISO 8601 | 書き出しのファイルには含めない。読み込んだときは、そのファイルを書き出した日時にする |
| review_requested_version | レビューのお願いを出したアプリの版 | 空なら、まだ出していない |
| whats_new_seen_version | 最後に見たお知らせの版 | 空なら、まだ見ていない。最初の設定を終えた時は、その時の一番新しい版にする |
| review_seen_reports | 開いた締めのレポートの期間の鍵（`month:2026-10-01` の形）を , でつないだもの | 週・月・年ごとに、最後に開いた 1 つだけを残す |

closed_hints に入る画面の名前は、次のとおり。

- `categories`
- `wallets`
- `templates`
- `recurrings`
- `stamps`
- `rewards`
- `budgets`
- `themes`
- `homeSections`
- `themeText`
- `themeLook`
- `reminder`
- `monthStartDay`
- `launchScreen`
- `sync`
- `backup`
- `appIcons`
- `widgetGuide`

### review_comment

締めのレポートの一手の理由（AI の文）を、締めた期間ごとに 1 行持つ。iOS だけに持ち、同期・書き出しには入れない。決定は [decisions/ai-review.md](decisions/ai-review.md#一手の理由の保存) にある。

| 列 | 型 | 補足 |
| --- | --- | --- |
| period | TEXT | 主キー。`month:2026-11-01` のように、週・月・年と期間の初日をつなぐ |
| body | TEXT | 一手の理由の文 |
| suggestion | TEXT | 今は空文字 |
| basis | TEXT | 作った時にモデルへ渡した事実の文。変わったら作り直す |
| created_at | TEXT | |
| breakdown | TEXT | 今は書かない（NULL） |

### review_goal

振り返りを開いた時に決めた一手（`ReviewGoal`）を、1 つずつ 1 行で持つ。iOS だけに持ち、同期・書き出しには入れない。決定は [decisions/review-report.md](decisions/review-report.md#一手の保存) にある。

| 列 | 型 | 補足 |
| --- | --- | --- |
| id | TEXT | 主キー |
| period | TEXT | 一手を守る期間。形は `review_comment` の period と同じで、索引を張る |
| kind | TEXT | `count`（回数）・`average`（1 回の平均） |
| category_id | TEXT | 対象のカテゴリ。カテゴリを消すと、一手も消える |
| memo | TEXT | 対象を同じメモの記録に絞る時のメモ。NULL はカテゴリ全体 |
| baseline | INTEGER | 決めた時の値。回数か、1 回の平均の円 |
| target | INTEGER | 目標の値。期間の終わりにこの値以下なら達成 |
| saving | INTEGER | 守れた時に浮く金額の見込み（円） |
| result | INTEGER | 締めた時の実際の値。答え合わせの前は NULL |
| saved | INTEGER | 締めた時に浮いた金額（円）。答え合わせの前は NULL |
| created_at | TEXT | |
| checked_at | TEXT | 答え合わせをした日時。答え合わせの前は NULL |
