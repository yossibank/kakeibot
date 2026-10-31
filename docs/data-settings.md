# 設定とテーマの表

> [!NOTE]
> テーマの表と、設定の表の形が分かる。
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
| entry_starts_with_amount | 新しい記録の入力シートを、テンキーを開いて始めるか。`true` `false` | 空なら `true` |
| categories_by_use | 今は使わない | |
| template_order | `manual` `frequent` `category` `amount` `name` | 空なら並べた順 |
| home_sections | ホームに並べる順。`customize` `budget` `templates` `recent` `bills` `stamps` を `,` でつないだもの | 空なら `customize` `budget` `templates` `recent` の順。無いものは後ろに足し、`bills` と `stamps` は非表示にする |
| home_hidden_sections | ホームに出さないもの。書き方は home_sections と同じで、すべては非表示にしない | 空なら home_sections にあるものをすべて出す |
| records_layout | `calendar` `list` | 空ならカレンダー |
| review_scale | `week` `month` `year` | 空なら月 |
| review_kind | `expense` `income` `balance` | 空なら支出 |
| closed_hints | 説明を閉じた設定の画面を `,` でつないだもの | 空ならすべて出す。画面の名前は、表の下の一覧にある |
| closed_hidden_lists | 非表示の項目をたたんだ設定の画面。書き方は closed_hints と同じ | 空ならすべて開く |
| recent_searches | 記録の検索で探した言葉を、新しい順に改行でつないだもの。5 つまで | |
| widget_entry | すぐ記録のウィジェットで最後に記録した entry の id。取り消すと消す | その記録で支出なしの印を消したときは、`,` に続けてその日付（`2026-10-03`）を付ける |
| fee_category_id | 振替の手数料に付ける category の id | |
| transfer_out_category_id | 抜けた共有の財布への振替を、支出に変えるときに付ける category の id | |
| transfer_in_category_id | 抜けた共有の財布からの振替を、収入に変えるときに付ける category の id | |
| backup_exported_at | バックアップを JSON で最後に書き出した日時。ISO 8601 | 書き出しのファイルには含めない。読み込んだときは、そのファイルを書き出した日時にする |
| review_requested_version | レビューのお願いを出したアプリの版 | 空なら、まだ出していない |

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
