# 設定の一覧の画面の足し方

> [!NOTE]
> 並べ替えのできる設定の一覧の画面を足す順と、画面ごとの違いの書き方が分かる。
> 使う部品は [architecture-parts](architecture-parts.md) にある。

## 🪜 設定の一覧の画面を足す

並べ替えのできる設定の一覧は、次の順で足す。

| 順 | すること | 書く所 |
| --- | --- | --- |
| 1 | モデルを `SettingsBoardListModel` と `SettingsBoardModel` に適合させる | `<単数>ListModel` |
| 2 | 設定の型を 1 つ書き、`SettingsBoardSpec` に適合させる | `<単数>Board` |
| 3 | 画面は、`body` で `SettingsBoardPage` を返すだけにする | `<単数>ListView` |

設定の型の例は、`StampBoard` と `CategoryBoard` にある。行の画面は `WalletBoard`、合計のカードを持つ画面は `RecurringBoard` を見る。`CategoryBoard` は、支出と収入の切り替えを `header` に持つ。

## 📏 画面ごとの違いの書き方

`SettingsBoardSpec` の要素のうち、既定の実装がある所は、違う画面だけが書く。

| 違い | 書く所 | 例 |
| --- | --- | --- |
| 行の画面 | `layout` を `swipeRows` か `swipeCards` にし、`grid` を 1 列にする。`tile` は行の部品を返す | `WalletBoard`・`RecurringBoard`・`TemplateBoard` |
| 持ち上げの倍率・余白 | `liftScale`・`scrollMargin` | `WalletBoard`（1.03）・`TemplateBoard`（余白 20） |
| 一覧の上の合計のカード | `lead(in:)`。タイルの並びの前に出る | `RecurringBoard` |
| 非表示にした時の文言 | `hideMessage` | `RecurringBoard` |
| 非表示・削除の前の確認 | `hideConfirmation`・`deleteConfirmation`。無ければ確認せずに行う | `WalletBoard`（非表示は残高がある時だけ）・`RecurringBoard` |
| 文字の大きさをそろえる | `scaleID(in:)`。変わると、そろえ直す | `WalletBoard`・`RecurringBoard` |
| 編集画面 | `typealias Editor` を書き、`editModel(for:)` を 1 つ書く | 全部の `Board` |
| 種類の切り替え | `header(in:)` に `CapsulePicker` を置く。行き先の型はモデルに書き、種類を持たせる | `CategoryBoard`・`RecurringBoard`・`TemplateBoard` |
| モデルを外から渡す | `makeModel()` が、持っているモデルを返す | `RecurringBoard` |
