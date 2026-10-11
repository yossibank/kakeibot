# 決めたこと

今有効な決定だけを書く。決定を変えたら行を書き換える。

## 作り方

| 項目 | 決定 | 理由 | 選ばなかった案 |
| --- | --- | --- | --- |
| 共通化 | Swift で先に作り、fixtures で Kotlin 版とそろえる | Swift が得意で iPhone を毎日使う。Android に取りかかるのは 6 番。AI の段階は Swift 専用 | Kotlin Multiplatform、Compose Multiplatform、Flutter、Swift SDK for Android |
| リポジトリ | 1 つにまとめる | fixtures と書き出しの形式を両 OS で共有する | OS ごとに分ける |
| 対応端末 | iPhone のみ | iPad 向けの画面の配置とスクリーンショットが要らない。あとから足せる | iPhone と iPad |
| 署名 | 自動 | 1 人・端末 1 台・CI なしなので、端末の追加・更新・提出を Xcode に任せられる | 手動 |
| プロジェクトのファイル | `.xcodeproj` をそのまま管理する | 1 人なので衝突しない。中身はほぼパッケージ側 | XcodeGen、Tuist |
| 整形 | SwiftFormat（Mint で版を固定）。commit の前に pre-commit が整形し、直したら commit を止める。ステージし直すのは人 | 自分で整形を走らせずに済む。一部だけステージしたファイルは、pre-commit が整形を取り消すので壊れない | hook は違反を止めるだけで直さない、hook がステージし直して commit まで通す、SwiftLint も入れる |
| 文書の確認 | 自動では確かめない | 文書が少なく、名前の変更もまれ | hook でリンク切れ・Mermaid の図を確かめる |

## iOS の構成

| 項目 | 決定 | 理由 | 選ばなかった案 |
| --- | --- | --- | --- |
| パッケージ | KakeibotKit（iOS・macOS）と KakeibotApp（iOS 専用）の 2 つ | 1 つにすると Core の `swift test` が iOS 専用ターゲットのせいで失敗する（確認済み） | 1 つのパッケージにターゲットを分けて入れる |
| 画面の作り | SwiftUI ＋ `@Observable`、処理のある画面だけモデル | 計算は Core にあり、テストもされる | TCA、全画面に ViewModel |
| Features | 1 つのターゲット、画面ごとのフォルダ | 1 人では、ターゲットを分ける管理の手間が勝つ | 機能ごとにターゲットを分ける |
| 部品の置き場所 | 値を表示するだけの部品は DesignSystem、データを読み書きするものは Features | 部品の置き場所を 1 つにする | Features の中に Shared/ を置く |
| 依存を渡す方法 | モデルを作るときに引数で渡す。Environment で渡すのはテーマだけ | `@State` でモデルを作る時点で Environment を読めない | Environment、部品をまとめた型 |
| DB | GRDB の DatabasePool を App Group に置く | SQL で集計と移行を書ける。ウィジェットからも読める | SwiftData、SQLDelight |
| DB の変更を画面に届ける | `ValueObservation` | 依存を増やさない | GRDBQuery、SQLiteData |
| 書き出しの形式 | Core に置く | DB なしで往復を試せる。Android に移せる | Store に置く |
| 通知 | 予約されているべき通知は Core で計算し、Notifications は差だけを OS に反映する | fixtures で試せる | Notifications が DB を読む |
| 入力の入口 | どこからでも開けるシート | 1 手で記録できる | 入力用のタブ |

## データ

| 項目 | 決定 | 理由 | 選ばなかった案 |
| --- | --- | --- | --- |
| 財布の種類 | 現金・銀行・カード・電子マネー・ポイント | カードの引き落としを銀行からの振替で記録する | 銀行なし |
| 期間の呼び方 | 期間の終わりが入っている月 | 1 日始まりでも給料日始まりでも同じ決まりで済む | 期間の始まりの月 |
| 支出なしの日 | 印を作る（`no_spend_day`） | 印がないと、支出のない日にも記録忘れの通知が来る | 作らない |
| 予算の履歴 | 「この月から」の行を足す | 額を変えても過去の月が変わらない。月替わりの写し作業が要らない | 月ごとに全カテゴリを写す、履歴なし |
| よく使う組み合わせ | 記録から自動で出す | 表が要らない | 自分で固定する |
