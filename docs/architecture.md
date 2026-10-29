# 構成

> [!NOTE]
> kakeibot の今の形のうち、共通の iOS の構成から外れた点と、kakeibot だけの事実が分かる。
> 共通の形は [claude-config の architecture-ios](https://github.com/yossibank/claude-config/blob/main/docs/architecture-ios.md) にある。
> 手元の置き場所は、claude-config の `docs/architecture-ios.md` である。

## 使う技術

iOS の言語は Swift 6 で、ほかの技術は共通の形と同じである。画面と保存を選んだ理由は、decisions の[画面の作り](decisions/ios.md#画面の作り)と [DB](decisions/ios.md#db) にある。Android は、次の技術を使う。

| 項目 | Android |
| --- | --- |
| 言語 | Kotlin |
| 画面 | Jetpack Compose |
| 保存 | Room（SQLite）。表の形は iOS と同じ |
| ウィジェット | Glance |
| 通信 | なし |

両 OS の分け方とそろえ方は、[decisions/build.md の「共通化」](decisions/build.md#共通化)にある。

## リポジトリ

共通の木に、次のものを足している。

| パス | 中身 |
| --- | --- |
| `android/` | 未着手 |
| `scripts/docs-check.py` | 文書と実物の一致を確かめる。リンク先とその見出し、Makefile の入口、この文書のパッケージの木を見る |
| `scripts/docs-check.py` の fixtures | fixtures の `description` と `summary` も見る |
| `spec/` | `export-format.md`、`fixtures.md`、`fixtures/` |
| `spec/fixtures/` | フォルダ名は、Core のフォルダ名の小文字にそろえる |
| `.claude/rules/` | spec の文書の役割 |
| `.claude/snapshots/widget/` | `ui-snapshot` で描くウィジェットの場合。あといくらの小・中、ロック画面の丸・横長・1 行 |
| `.claude/snapshots/recent-transfers/` | `ui-snapshot` で描く、入力シートの最近の振替の行。長い口座名、手数料の有無 |
| `.claude/snapshots/entry-sheet/` | `ui-snapshot` で描く入力シートの全体（支出・振替）。カテゴリの格子は描かれない |
| `.claude/snapshots/records/` | `ui-snapshot` で描く記録のタブ。カレンダーと一覧 |
| `.claude/snapshots/review/` | `ui-snapshot` で描く振り返りのタブ |
| `.claude/snapshots/assets/` | `ui-snapshot` で描く資産のタブ |
| `.claude/snapshots/home/` | `ui-snapshot` で描くホームのタブ |
| `.claude/snapshots/settings/` | `ui-snapshot` で描く設定。メニュー・口座・ごほうび・記録忘れの通知 |
| `.claude/snapshots/theme-style/` | `ui-snapshot` で描く、文字と角の丸みの見本 |
| `.claude/snapshots/home-sections/` | `ui-snapshot` で描く、ホームの並べ替え |
| `.claude/snapshots/parts/` | `ui-snapshot` で描く、カレンダー・タグ・テンプレートのカード |

## ios

ターゲットと ID は、共通の形の `<App>` を `Kakeibot` にしたものである。ほかに、次のものを持つ。

| 項目 | アプリ | ウィジェット |
| --- | --- | --- |
| アプリアイコン | Icon Composer の `AppIcon.icon`（ホワイト） | |
| アイコンの色違い | 設定で選べる色違いは、同じフォルダの `AppIcon-<色>.icon` | |
| アイコンの見本 | `Assets.xcassets` の `AppIconYen`・`AppIconDial`。設定の見本に描く、アイコンと同じ絵の写し | |
| 同梱のフォント | `Kakeibot/Fonts` の TTF と、そのライセンスの文。Info.plist の `UIAppFonts` で読む | アプリのものを `WidgetFonts` で読む |
| 共有の受け入れ | Info.plist の `CKSharingSupported`。AppFeature の `AppDelegate` が、シーンの delegate を差し替えて共有のリンクを受け取る | |

`license_plist.yml` には、同梱のフォントと配布元のライセンスを手で足す。

### 署名

| 項目 | 状態 |
| --- | --- |
| チーム | `6WHPY5MQSB`（Apple Developer Program に加入済み） |
| 登録済みの端末 | 自分の iPhone 1 台 |
| 開発用の証明書 | 2027-01-25 まで |
| プロファイル | 2027-10-10 まで |
| 配布用の証明書 | なし。Archive のときに Xcode がクラウドで管理するものを使う |

## パッケージ

2 つのパッケージの中身は、次のとおりである。共通の形に無い `Store/Snapshot/`・`Store/Sync/` と、`Sync` を足している。依存の向きは、共通の形に `AppFeature --> Sync --> Store` を足したものである。

### KakeibotKit

KakeibotKit のフォルダは、次の木のとおりである。

```text
KakeibotKit/
├── Sources/
│   ├── Core/
│   │   ├── Budget/
│   │   ├── Category/
│   │   ├── Date/
│   │   ├── Entry/
│   │   ├── Export/V1/
│   │   ├── Icon/
│   │   ├── Identifier/
│   │   ├── Notification/
│   │   ├── Recurring/
│   │   ├── Review/
│   │   ├── Reward/
│   │   ├── Setting/
│   │   └── Wallet/
│   └── Store/
│       ├── Database/
│       ├── Migrations/
│       ├── Queries/
│       ├── Records/
│       ├── Snapshot/
│       ├── Sync/
│       └── Writes/
└── Tests/
```

フォルダごとの中身は、次のとおり。

| フォルダ | 中身 |
| --- | --- |
| `Core/Budget/` | 予算と消化 |
| `Core/Category/` | 記録のカテゴリとタグ |
| `Core/Date/` | LocalDate、期間の区切り、祝日 |
| `Core/Entry/` | 記録、金額の電卓、日ごとのまとめ |
| `Core/Export/V1/` | 書き出しの形 |
| `Core/Icon/` | アイコンとスタンプ |
| `Core/Identifier/` | 型付きの ID |
| `Core/Notification/` | 予約されているべき通知の計算と行き先 |
| `Core/Recurring/` | 固定費と記録漏れの後追い |
| `Core/Review/` | 振り返りの範囲と集計 |
| `Core/Reward/` | ごほうびと貯金箱 |
| `Core/Setting/` | 設定の値とテーマ |
| `Core/Wallet/` | 財布と残高 |
| `Store/Database/` | 最初の財布とカテゴリも作る。止める通知は AppFeature が送る |
| `Store/Snapshot/` | 書き出し用の全データの読み出し、読み込み用の全置き換え |
| `Store/Sync/` | 同期で送る行の記録と、受け取った行の書き込み |
| `Store/Writes/` | ウィジェットからの記録と取り消しも含む |

### KakeibotApp

KakeibotApp のフォルダは、次の木のとおりである。

```text
KakeibotApp/
├── Sources/
│   ├── AppFeature/
│   ├── AppWidget/
│   ├── DesignSystem/
│   │   ├── Components/
│   │   └── Theme/
│   ├── Features/
│   │   ├── Screens/
│   │   │   ├── Entry/
│   │   │   ├── Onboarding/
│   │   │   ├── Settings/
│   │   │   └── Tabs/
│   │   └── Shared/
│   │       ├── Model/
│   │       ├── Notice/
│   │       ├── Period/
│   │       ├── Settings/
│   │       └── Setup/
│   ├── Notifications/
│   └── Sync/
└── Tests/
```

フォルダごとの中身は、次のとおり。

| フォルダ | 中身 |
| --- | --- |
| `AppFeature/` | 起動の印の動き、通知の許可、入力の準備も持つ |
| `AppWidget/` | すぐ記録の記録と取り消し、コントロールの「記録する」 |
| `DesignSystem/Components/` | Amount・Banner・Button・Calendar・Chart・Dial・Gesture・Icon・Input・Menu・Navigation・Row・Sheet・Surface・Tag・Template |
| `Features/Screens/Entry/` | 記録の入力シート |
| `Features/Screens/Onboarding/` | 最初の設定のチュートリアル |
| `Features/Screens/Settings/` | 設定の項目ごとの画面。Menu は入口と、確かめ用のテストデータ（`#if DEBUG`） |
| `Features/Screens/Tabs/` | Assets・Home・Records・Review |
| `Features/Shared/Model/` | 画面のモデルの見張りの形（失敗したら見張り直す）、記録の検索と絞り込み |
| `Features/Shared/Notice/` | 記録・削除の知らせと取り消し、読み込めないときの表示、保存の失敗が空き容量不足かの見分け |
| `Features/Shared/Period/` | 期間の範囲と月の始まり |
| `Features/Shared/Settings/` | 設定の画面で使う部品（Board・Header・Hint・Icon・Input・Preview・Tile） |
| `Features/Shared/Setup/` | 残りの設定とカスタマイズの項目と進み具合 |
| `Sync/` | CKSyncEngine で変更を送り受けする。財布の共有、共有シート、共有の受け入れも作る |

## 名前の決まり

フォルダとファイルの名前は、共通の形の「名前の決まり」と `rules/swift-core.md` に従う。kakeibot では、入れる先のない `Core/Identifier` だけ、ファイルが 1 つのフォルダを認める。fixtures は `spec/fixtures/` の下の、Core のフォルダ名を小文字にしたフォルダに置く。

## 画面の組み立て

AppModel と MainView は、共通の形に加えて、次のものを持つ。

| 型 | 持つもの |
| --- | --- |
| AppModel | 最初の設定が済んでいなければ Onboarding を出す。今日は RootView が MainView と Onboarding に渡す |
| MainView | タブは Home・Records・Review・Assets。Home 以外のタブは、最初に開いたときに見張りを始める |
| MainView のシート | 新規・編集・設定・振替など。テンプレート（`EntryTemplate`）・口座（`Wallet`）・固定費（`Recurring`）も開く |

記録の一覧（`EntryList`）の見張りは、`AppDatabase` が 1 つだけ持つ。見張りの型は `ValueObservation` で、次のように使う。

- 見張る画面と入力シートのあいだで共有する。中身が変わらない書き込みでは、値を渡さない
- 月の集計（`MonthOverview`）と通知の入力（`NotificationInput`）も、この一覧から作る。ほかの表は、小さな問い合わせで足す

### 見張り直し

見張りが止まったときの見張り直しは、次の決まりで動く。

| 対象 | 動き |
| --- | --- |
| 各画面の見張り | 失敗したら、1 秒・2 秒・4 秒待って見張り直す。3 回を超えたら知らせを出して止める |
| AppModel の見張り | テーマ・ウィジェット・通知を見張る。同じ待ちで見張り直し、止まったときは知らせを出さない |
| 回数 | 1 回の見張りの中で数え、値を受けても戻さない |
| RootView | DB が使えるかどうかと今日が変わるたびに、AppModel の見張りを張り直す |
| 前面に戻った時 | MainView が各画面の見張りを始め直す。AppModel の見張りは、止まったものがあるときだけ RootView が始め直す |
| 裏に回った印 | 裏に回ったことを覚えておき、inactive を挟んで戻っても検出する |
| 止まった画面 | ホーム・記録・振り返り・資産は、「読み込めませんでした」と「もう一度読み込む」を出す |

### 保存から反映まで

テンプレートから記録した時に、各画面と通知へ反映されるまでの流れである。

```mermaid
sequenceDiagram
    actor U as 利用者
    participant HM as HomeModel
    participant S as Store
    participant M as 各画面のモデル
    participant AM as AppModel

    U->>HM: テンプレートをタップ
    HM->>S: 記録を書く
    S-->>M: ValueObservation で変更を知らせる
    S-->>AM: ValueObservation で変更を知らせる
    AM->>AM: 通知を予約し直す
```

AppModel は、今日からの記録と支出なしの印、通知の時刻、固定費を見張る。どれかが変わると、記録忘れの通知と固定費の更新前の通知を予約し直す。

### 起動と画面復帰

共通の表の処理に加えて、起動・前面に戻る・日付が変わる時に、固定費の記録漏れを作る。`0xdead10cc` で終了しないことは、実機で書き込みの最中に裏に回して確かめた。

### 外からの入口

外から開く入口と、その開く先は次のとおりである。

| 入口 | 開く先 |
| --- | --- |
| ウィジェット | ホーム |
| すぐ記録の金額を決めていないテンプレート | 入力シート（そのテンプレート） |
| コントロールの「記録する」 | 入力シート（今日） |
| 記録忘れの通知 | 入力シート（今日） |
| 固定費の更新前の通知 | 設定 → 固定費 → その固定費 |

行き先は、通知と同じ `PlannedNotification.Route` で表す。ウィジェットからは、行き先の文字列を `kakeibot://home` のような URL にして渡す。起動したときは、起動画面が消えてから行き先を開き、起動時に開く画面は開かない。

コントロールの「記録する」は、AppIntent をアプリの中で動かす。行き先は `NotificationRouter` に渡す。このインテントのため、`Kakeibot` も AppWidget と AppIntents.framework をつなぐ。

## 通知とウィジェット

通知とウィジェットの方式は、次のとおりである。

| 対象 | 方式 |
| --- | --- |
| 記録忘れの通知 | 30 日先まで予約し、当日の記録か支出なしの印ができたら当日分を取り消す |
| 固定費の更新前の通知 | 更新日の N 日前で予約する |
| iOS のウィジェットの読み出し | AppWidget が `AppDatabase.appGroupForReading()` で DB を読むだけで開く。表の形が最新でなければ読まない |
| iOS のウィジェットの読み出しの範囲 | 記録は、今月の 4 か月前の月初か 90 日前の早いほうからと、そこからの固定費・請求月に当たるものだけを読む |
| iOS のウィジェットの描き方 | ホームと同じ `MonthOverview` を使う。背景は、テーマ（`ThemePalette`）の色の値から作った色で描く |
| iOS のウィジェットの更新 | AppModel が、記録・予算・固定費・テンプレートとその並べ順・テーマの変化を見張って更新する。日付が変わるときはタイムラインで切り替える |
| すぐ記録の書き込み | 押したときだけ、AppIntent が `appGroupForWriting()` で開いて書く。通知を予約し直し、すべてのウィジェットを更新する |

## テスト

テストの形は、共通の形と同じである。Core のテストは、fixtures を全部通す。

## 未検証

> [!WARNING]
> - パッケージの中のフォントを、起動時の登録で使えるか（DesignSystem を作るとき）
> - 配布用の証明書を Xcode がクラウドで管理するか（12 番で確かめる）
> - すぐ記録を押したとき、ウィジェットの拡張から DB に書け、アプリを前面に戻すと画面に出るか。ホーム画面で押して確かめる
> - ロック中に、ロック画面のウィジェットが金額を出すか（実機）。ファイル保護は、アプリと拡張でそろえた。値は `NSFileProtectionCompleteUntilFirstUserAuthentication` である
