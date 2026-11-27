# Android の画面とモデルのやり取り

> [!NOTE]
> Android の画面がモデルを呼ぶ入口と、結果を受ける出口、モデルのテストの置き場所が分かる。
> モデルの書き方は [architecture-android-app](architecture-android-app.md) にある。

## 🪝 画面とモデルのやり取り

画面は、コルーチンを自分で始めない。入口と出口は iOS と同じ形で、iOS の決まりは [architecture-screens](architecture-screens.md) にある。

| 対象 | 決まり |
| --- | --- |
| 入口 | ボタンなどからモデルの suspend の関数を呼ぶ時は、`perform` に通す。`model.perform { it.save() }` と書く |
| 口の置き場所 | `featuremodels/shared/model/` の `ScreenPerforming`。使うモデルが適合を書く |
| 始まり | `perform` を呼んだ関数が戻ってから始まる。続けて呼ぶと、呼んだ順に始まる |
| 持ち主 | 始めた処理は誰も持たず、画面が消えても取り消さない。終わるまで続く |
| 画面の寿命に結び付く処理 | 監視と読み込みは、`LaunchedEffect` からモデルの関数を 1 つ呼ぶ。画面が消えると止まる |
| 出口 | 保存できた・消した、の結果は、モデルの `state` の `outcome` に置く。画面は戻り値を見ない |
| 結果の型 | `ScreenOutcome<値>`。値と送った回数を持ち、同じ値を続けて置いても届く |
| 受ける所 | 画面は、`features/shared/model/` の `OnOutcome` を 1 か所に書く。閉じる・親に知らせるだけを書く |
| 編集シートの結果 | `EditFlow.Outcome`。保存した値・非表示にしたか・消した物・閉じるかを持つ |
| 編集シートの流れ | `shared/model/` の `EditFlow` を、モデルが `val flow` で持つ。画面は `model.flow.output.x` を読み、`model.flow.close()` などを呼ぶ |
| 流れが持つ物 | 確認（`EditFlow.Prompt`）の `Shown` と、親と分け合う `ModelTask` を持つ。`output` は保存できるかと保存の題を出し、結果は `outcome` に置く |
| 流れの元 | モデルは `EditFlowSource` を private の入れ子の型で書く。隠す・消すの無いシートは既定の実装のままにし、失敗は投げて流れに知らせを出させる |
| 閉じる操作 | 変わっていれば捨てる確認を出し、変わっていなければ閉じる結果を `outcome` に置く。戻るは、開いている枠を `rest` で先に閉じる |
| 二度押し | 保存・削除・非表示は、`task` が動いている間は受けない |
| 画面の側 | `features/shared/model/` の `EditSheet` を書く。確認と戻るを持ち、結果で `onSaved`・`onClose` などを呼ぶ |
| 当てた画面 | 固定費の編集・テンプレートの追加・予算の数字の引き出し |
| 取り消しの知らせ | モデルが、`state` の `UndoNotice` に出す。予算と固定費の一覧・`EntryNoticeModel`・`EntryItemModel` が当たる |
| 子の画面の結果 | 親のモデルの `receive`・`receiveHidden` に渡す |
| 入力の結果 | `EntryModel.Outcome` の `Closed` と `Continued` が、`EntryChange` を持つ |
| アプリの入口 | `RootView` は `AppModel` の `state.launch` と `input` の今日・テーマを読む。`open`・`retryOpen`・`refreshDay` を呼ぶ |
| 残す `rememberCoroutineScope` | `designsystem` の動きだけが持つ。画面のファイルには書かない |

## 🧪 モデルのテスト

モデルのテストは `featuremodels/src/test/` に置く。`modelTest` が DB をメモリに開き、`ModelWait` が値を待つ。iOS と違う動きは `@Ignore` の理由に書く。

テストは、iOS のテストと 1 件ずつ結び付けて [scenarios](../spec/scenarios.md) の一覧に載せる。

入力の値だけで決まる画面の文は、`spec/fixtures` を読んで確かめる。読む部品は `support/ModelFixture.kt` で、iOS も同じファイルを読む。形式は [fixtures](../spec/fixtures.md) にある。

読み書きの失敗は、`support/AppDatabaseFailure.kt` で起こす。記録の一覧の失敗は、失敗する `Flow` をモデルに渡して起こす。やり直すと読める一覧は、`failingFirst` で作る。
