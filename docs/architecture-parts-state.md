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
| `notices` | `Notices` を `let` か `internal(set)` | `Notices` の class を `val` | モデル | 時間で消える知らせと、次の操作まで出す結果の文（バックアップの `done`）。エラーは `error` |
| `task` | `ModelTask` | `ModelTask` | モデル | 実行中の印 |
| `outcome` | `ScreenOutcome` | `ScreenOutcome` | モデル | 画面への結果 |
| `submodels` | `Submodels` の struct | `Submodels` の class | モデル | State が持つ子のモデル |

状態がエラーの知らせだけのモデルは、iOS では共通の `ErrorNoticeState` を使う。はじめの設定・月の始まり・起動の画面・アプリのアイコンが当たる。`State` の無いモデル（設定の説明カード）は、枠を持たせない。

### 表示中のものの続きは presented に置く

モデルだけが書く、表示中のものの続きも `presented` に置く。iOS は `public internal(set)` にし、画面は読むだけにする。

画面が何も書かない時は、`presented` も `public internal(set)` にする。

| モデル | `presented` の値 |
| --- | --- |
| Backup | 書き出すファイル（`file`）・読み込む前の確認の中身（`pending`）・押した行（`pressed`） |
| BudgetList | 金額を入れている予算（`editing`） |
| CategoryEdit | 編集中のタグ（`tagEdit`）と、その問題（`tagRejection`） |
| HomeSectionList | 引いている区画（`dragging`） |
| ThemeList | 勧めるアイコン（`suggestedIcon`）・押している行（`pressing`） |
| ThemeStyle | Pro の案内を出している字体（`fontOffer`）と、その見本（`preview`） |
| WalletEdit | 引き落としを聞いている、足したばかりの口座（`addedWallet`） |
| WidgetGuide | 見えている見本（`shownSample`） |
| EntryReceiptFlow・EntryVoiceFlow | 今の段（`step`） |

### どれを実行中かは task の鍵で持つ

iOS だけ。実行中の印と、どれを実行中かを別の値で持たない。

- 鍵は、モデルの入れ子の `Work` の enum にする
- `task.attempt(鍵)` で走らせ、画面は `task.isRunning(鍵)` で見る
- Android の `ModelTask` は、当たる画面が無いため鍵を持たない

| モデル | 鍵 | 中身 |
| --- | --- | --- |
| ProPurchase | `Work` | 購入（`purchase`）か復元（`restore`） |
| Sync | `Work` | 同期の切り替え（`switching`）か、口座の共有（`sharing(id)`）。共有の二度押しは `isRunning(where: \Work.isSharing)` で止める |

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

`make verify` の state-check が、直下の知らせ・裸の値・書ける `var` を見る。中身は [architecture](architecture.md#確かめるスクリプト) にある。型の無い値で裸と見るのは、文字どおりの値（`false`・`0`・`""`）と `mutableIntStateOf` などである。

### 部品の型は枠の中だけに置く

次の部品の型は、`State` の直下に置かず、枠の中に置く。同じ役目の値を 2 通りで書かないためである。

| 型 | 枠 |
| --- | --- |
| `ErrorNotice` | `notices.error` |
| `UndoNotice`（取り消しの知らせ） | `notices` の意味の名前（`notices.deletion` など） |
| `Shown` | `presented` の意味の名前 |
| 中に持つモデル・`AmountCalculator` | `submodels` の意味の名前（`submodels.icon` など） |

`errorNotice` の共通の読み口は残し、`notices.error` を返す。

### 選んでいる物は fields に置く

ID の型（`…ID`・`Identifier<…>`）も裸の値として扱う。その Optional・配列・Set も含む。

| 値の種類 | 例 | 行き先 |
| --- | --- | --- |
| 画面で選ぶ物 | 口座・カテゴリ・タグ・並べ替え中の並び | `fields`（`fields.walletId`・`fields.movingOrder`） |
| 表示中の行 | 横に払って開いた行 | `presented`（iOS は `presented.openId`、Android は `presented.row`） |
| モデルだけが決める物 | 共有を操作中の口座 | `task` の鍵（`Work.sharing(id)`） |

設定の一覧の `fields` は、iOS では `SettingsBoardFields` に適合させる。

画面が直に書かない入力は、`Fields` の中で `internal(set)` か `private(set)` にする。モデルの関数で確かめてから入れる。カテゴリの編集のタグと、アイコンの絵文字と文字と、オンボーディングの道筋が当たる。

Android の入力の下書きの `data class`（`EntryForm` など）は、`fields.form` に持つ。下書きの外の印（固定費の休日の扱いを人が選んだか）も、`fields` に並べる。

## 🪝 タブとメインの値の型

| モデル | 値の型 | 中身 |
| --- | --- | --- |
| Review | `PeriodCursor` | 期間のずれ（iOS は動く向きも）。`move(by:)`・`restart`・`moveToCurrent` |
| Records | `MonthCursor` | 表示中の月（iOS は動く向きも、Android は今月を nil） |
| Home | `PendingDay` | スタンプのシートで選んだ日。`pick`・`take` |
| Main | `TabSelection` | 今のタブと訪れたタブ。`select` |
| Main | `EntryLaunch` | 入力をレシートで始めるかと、先に温めている間か。iOS だけ |
| Entry | `Closing` | 保存か削除で閉じ始めた印。`begin`・`cancel`。iOS だけ |
| Entry | `FieldFocus` | 今の欄と、欄を進む向き。`moved`。Android だけ |
| RecurringEdit | `Repayment`（Android は `RecurringRepayment`） | 返済の回数と、回数を自動で決めるか、手で決めた最後の額。`useAutoCount` など（Android は `usingAutoCount` などの値を返す関数） |
| EntryVoice | `Rounds` | 聞き始めと聞き終わりの回。`start`・`end` |
| EntryVoice | `Silence` | 黙り始めた時刻。`start(at:)`・`clear`。iOS だけ |
| App | `Reveal` | 起動の幕と、輪を回し終えたか、ホームを読み終えたか。iOS だけ |
| WalletEdit | `BalanceSign` | 初めの残高の正負。種類を変えた時は、`follow` で新しい種類の向きに合わせる（iOS だけ） |
| Sync | `SwitchRequest` | 同期のスイッチを押してから、切り替え終わるまでの向き。`ask`・`clear`。iOS だけ |
| SettingsMenuValue | `Choice` | 保存中の選んだ値。`begin`・`end`・`clear`・`value(over:)`。iOS だけ |
| SettingsIconEditor | `Fields` | 印の種類・絵柄・色。絵文字と文字は `inputEmoji`・`inputText` で絞る（iOS だけ） |

Main の知らせを隠す回は、`notices.round` に置く。
