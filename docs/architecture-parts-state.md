# モデルの State の組み方

> [!NOTE]
> 画面のモデルの `State` に、何をどの名前で置くかが分かる。
> 部品は [architecture-parts](architecture-parts.md) にある。
> 画面が書く値は [architecture-screens-flow](architecture-screens-flow.md#-画面がモデルに書く値) にある。

## 🗺️ State の枠

モデルの `State` は、次の名前の枠で組む。要る枠だけを置き、中身が 1 つでも包む。

| 枠 | iOS | Android | 書く人 | 入れる物 |
| --- | --- | --- | --- | --- |
| `fields` | `Fields` の struct を `public var` | `Fields` の data class を `private set` | 画面 | 入力と選んでいる物 |
| `presented` | `Shown` を並べた `Presented` を `public var` | `Shown` を並べた `Presented` を `val` | 画面 | シート・確認・開いている行など |
| `notices` | `Notices` を `let` か `internal(set)` | `Notices` の class を `val` | モデル | 時間で消える知らせ。エラーは `error` |
| `task` | `ModelTask` | `ModelTask` | モデル | 実行中の印 |
| `outcome` | `ScreenOutcome` | `ScreenOutcome` | モデル | 画面への結果 |
| `submodels` | `Submodels` の struct | `Submodels` の class | モデル | State が持つ子のモデル |

## 📏 直下に置ける物

`State` の直下に置ける物は、次のものだけである。

- 枠
- 部品の型（`ObservationRound` など）
- 振る舞いを持つ値の型（1 概念 1 プロパティ）

書けるのはモデルだけにする。Swift は `private(set)` か `internal(set)` にする。Kotlin は `private set` にする。

裸の値は直下に置かない。裸の値とは、`Bool`・数・文字列・日付のことである。その Optional・配列・Set も含む。

裸の値は、次の行き先に送る。

| 値の種類 | 例 | 行き先 |
| --- | --- | --- |
| 外から来る値 | 今日・目標を確かめた時刻 | `input` |
| 計算できる値 | レビューのカードを出すか・新しい振り返り | `output`。見た印は `input` に持つ |
| 表示中のものの続き | シートを閉じた後に開く物・消す前の確認の行 | `presented` |
| 一緒に変わる値 | 期間のずれと動く向き | 変え方の関数を持つ値の型（`PeriodCursor`） |
| 1 つだけの途中の値 | スタンプのシートで選んだ日 | 意味の名前の値の型（`PendingDay`） |

値の型には、モデル抜きのテストを書く。

## 🪝 タブとメインの値の型

| モデル | 値の型 | 中身 |
| --- | --- | --- |
| Review | `PeriodCursor` | 期間のずれ（iOS は動く向きも）。`move(by:)`・`restart`・`moveToCurrent` |
| Records | `MonthCursor` | 表示中の月（iOS は動く向きも、Android は今月を nil） |
| Home | `PendingDay` | スタンプのシートで選んだ日。`pick`・`take` |
| Main | `TabSelection` | 今のタブと訪れたタブ。`select` |
| Main | `EntryLaunch` | 入力をレシートで始めるかと、先に温めている間か。iOS だけ |
| WalletEdit | `BalanceSign` | 初めの残高の正負。前の種類の向きのままなら、`follow` で新しい種類に合わせる（iOS だけ） |
| Sync | `SwitchRequest` | 同期のスイッチを押してから、切り替え終わるまでの向き。`ask`・`clear`（iOS だけ） |

Main の知らせを隠す回は、`notices.round` に置く。
