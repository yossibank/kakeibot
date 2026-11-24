# パッケージの構成

> [!NOTE]
> 2 つのパッケージの依存の向きと、フォルダごとの中身が分かる。
> 全体の構成は [architecture](architecture.md) にある。

## 📦 パッケージ

2 つのパッケージの中身は、次のとおりである。共通の形に無い `Store/Snapshot/`・`Store/Sync/`・`Sync`・`TestSupport` を足している。画面のモデルは、`Features` から `FeatureModels` に分けている。

依存の向きは、共通の形に次の 3 本を足したものである。

- `AppFeature --> Sync --> Store`
- `AppFeature・Features --> FeatureModels`
- `AppFeatureTests・FeaturesTests --> TestSupport`

テストのターゲットを除いた依存は、次の図のとおりである。

```mermaid
flowchart TD
    subgraph app["KakeibotApp"]
        AppFeature --> Features
        AppFeature --> FeatureModels
        Features --> FeatureModels
        FeatureModels --> DesignSystem
        AppFeature --> Notifications
        AppFeature --> Sync
        AppFeature --> DesignSystem
        AppWidget --> Notifications
        AppWidget --> DesignSystem
        Features --> DesignSystem
    end
    subgraph kit["KakeibotKit"]
        Store --> Core
    end
    AppFeature --> Store
    AppWidget --> Store
    Features --> Store
    FeatureModels --> Store
    Sync --> Store
    AppFeature --> Core
    AppWidget --> Core
    Features --> Core
    FeatureModels --> Core
    Notifications --> Core
    DesignSystem --> Core
    Store --> GRDB
```

### KakeibotKit

KakeibotKit のフォルダは、次の木のとおりである。

```text
KakeibotKit/
├── Sources/
│   ├── Core/
│   │   ├── Concepts/
│   │   │   ├── App/
│   │   │   ├── Budget/
│   │   │   ├── Category/
│   │   │   ├── Date/
│   │   │   ├── Entry/
│   │   │   ├── Export/V1/
│   │   │   ├── Icon/
│   │   │   ├── Notification/
│   │   │   ├── Receipt/
│   │   │   ├── Recurring/
│   │   │   ├── Review/
│   │   │   ├── Reward/
│   │   │   ├── Setting/
│   │   │   ├── Theme/
│   │   │   ├── Voice/
│   │   │   └── Wallet/
│   │   └── Shared/
│   └── Store/
│       ├── Database/
│       ├── Migrations/
│       ├── Queries/
│       │   ├── Methods/
│       │   └── Types/
│       ├── Records/
│       │   ├── Protocols/
│       │   ├── Rows/
│       │   ├── SettingKeys/
│       │   └── Values/
│       ├── Snapshot/
│       ├── Sync/
│       │   ├── Methods/
│       │   └── Types/
│       └── Writes/
│           ├── Methods/
│           └── Types/
└── Tests/
```

フォルダごとの中身は、次のとおり。

| フォルダ | 中身 |
| --- | --- |
| `Concepts/App/` | アプリの版 |
| `Concepts/Budget/` | 予算と消化 |
| `Concepts/Category/` | 記録のカテゴリとタグ |
| `Concepts/Date/` | LocalDate、期間の区切り、祝日、休日のずらし |
| `Concepts/Entry/` | 記録と品目、金額の電卓、日ごとのまとめ |
| `Concepts/Export/V1/` | 書き出しの形 |
| `Concepts/Icon/` | アイコンとスタンプ |
| `Concepts/Notification/` | 予約されているべき通知の計算と行き先 |
| `Concepts/Receipt/` | 文字の断片をレシートの行にまとめ、行かモデルが答えた行の役割から品目・合計・日付・店名を組み立てる決まり。人が直した品名 |
| `Concepts/Recurring/` | 固定費と記録漏れの後追い |
| `Concepts/Review/` | 振り返りの範囲と集計 |
| `Concepts/Reward/` | ごほうびと貯金箱 |
| `Concepts/Setting/` | 設定の値 |
| `Concepts/Theme/` | テーマの色・書体・形 |
| `Concepts/Voice/` | 話した文から金額・日付・カテゴリ・口座・メモを読む決まり |
| `Concepts/Wallet/` | 財布と残高 |
| `Core/Shared/` | 概念をまたいで使う型。型付きの ID、割合、金額の表記、下書きの決まりと問題、文字の前後の空白を除く拡張 |
| `Core/Shared/` の `NamedIconDraft` | 名前とアイコンを持つ下書き。カテゴリと口座の下書きが適合する |
| `Store/Queries/`・`Store/Sync/`・`Store/Writes/` | `Methods/` に `AppDatabase+*.swift` の拡張、`Types/` にそれ以外の型を置く |
| `Store/Queries/Methods/` | 返す型の名前で付ける。書き込みと同じ型なら `+<型>Query` |
| `Store/Records/` | 表の行・設定のキー・列の値の適合。`Protocols/` に並べ替え・非表示・アイコン付きの行の決まりを置く |
| `Store/Migrations/` | `MigrationV<3 桁の通し番号>.swift`。欠番は 14。同期のトリガーを作る固定の SQL は `MigrationSyncTriggers.swift` |
| `Store/Database/` | 最初の財布とカテゴリも作る。止める通知は AppFeature が送る |
| `Store/Snapshot/` | 書き出し用の全データの読み出し、読み込み用の全置き換え |
| `Store/Sync/` | 同期で送る行の記録と、受け取った行の書き込み |
| `Store/Writes/` | ウィジェットからの記録と取り消しも含む。並べ替え・非表示・アイコン付きの保存の共通の関数は `Methods/` に、その下書きの決まりは `Types/` に置く |

### KakeibotApp

KakeibotApp のフォルダは、次の木のとおりである。

```text
KakeibotApp/
├── Sources/
│   ├── AppFeature/
│   │   ├── App/
│   │   ├── Bridge/
│   │   └── Main/
│   ├── AppWidget/
│   │   ├── Intents/
│   │   ├── Shared/
│   │   └── Widgets/
│   │       ├── Budget/
│   │       ├── EntryControl/
│   │       └── QuickRecord/
│   ├── DesignSystem/
│   │   ├── Components/
│   │   └── Theme/
│   ├── FeatureModels/
│   │   ├── Screens/
│   │   │   ├── Entry/
│   │   │   ├── Onboarding/
│   │   │   ├── Pro/
│   │   │   ├── Settings/
│   │   │   └── Tabs/
│   │   └── Shared/
│   │       ├── Bill/
│   │       ├── DateChoice/
│   │       ├── EntryList/
│   │       ├── Model/
│   │       ├── Notice/
│   │       ├── Notification/
│   │       ├── Period/
│   │       ├── Pro/
│   │       ├── SettingsParts/
│   │       ├── Setup/
│   │       └── Stamp/
│   ├── Features/
│   │   ├── Screens/
│   │   │   ├── Entry/
│   │   │   ├── Onboarding/
│   │   │   ├── Pro/
│   │   │   ├── Settings/
│   │   │   ├── Tabs/
│   │   │   └── WhatsNew/
│   │   └── Shared/
│   │       ├── Bill/
│   │       ├── DateChoice/
│   │       ├── FeatureArt/
│   │       ├── Notice/
│   │       ├── Notification/
│   │       ├── Period/
│   │       ├── Placeholder/
│   │       ├── Pro/
│   │       ├── SettingsParts/
│   │       ├── Setup/
│   │       ├── Stamp/
│   │       └── Wallet/
│   ├── Notifications/
│   └── Sync/
└── Tests/
```

フォルダごとの中身は、次のとおり。

| フォルダ | 中身 |
| --- | --- |
| `AppFeature/App/` | アプリの入口と起動、起動の印の動き、入力の準備、レビューのお願い。Pro が無くなったら同期を止める |
| `AppFeature/Bridge/` | Pro の購入を StoreKit で確かめる。iCloud のアカウントと共有の参加者を CloudKit で読む |
| `AppFeature/Main/` | 4 つのタブと入力シートなどのシートを組む |
| `AppWidget/Intents/` | すぐ記録の記録と取り消し、コントロールの「記録する」 |
| `AppWidget/Shared/` | ウィジェットをまたいで使う読み出し・書体・テーマ・タイムライン |
| `AppWidget/Widgets/` | ウィジェットごとのフォルダ。コントロールの「記録する」は `EntryControl/` |
| `FeatureModels/` | 画面のモデルと、モデルが使う値の型・文言・読み取り。フォルダは `Features/` と同じ形にする |
| `FeatureModels/Screens/Entry/` | 記録の入力シートのモデル |
| `FeatureModels/Screens/Entry/Receipt/` | レシートを Vision と Foundation Models で読む |
| `FeatureModels/Screens/Entry/Voice/` | 声を SpeechAnalyzer で聞き、Foundation Models でカテゴリと口座を選ぶ |
| `FeatureModels/Screens/Pro/` | Pro の購入のモデル |
| `FeatureModels/Shared/Bill/` | これからの引き落としを月のページに分ける |
| `FeatureModels/Shared/DateChoice/` | 休日のずらしと曜日の表示の名前 |
| `FeatureModels/Shared/EntryList/` | 記録の一覧の検索と絞り込み、一覧の行に出す値、記録で選べるカテゴリ・タグ・アイコンと、口座の見出しの言葉 |
| `FeatureModels/Shared/Model/` | 画面のモデルの見張り（失敗で見張り直す）、読み込みと知らせの状態、文言に出す端末の名前（iPhone か iPad）。設定を失敗で戻す形、`ScreenClock`、値を覚える `Derived`・`DerivedTable` も置く |
| `FeatureModels/Shared/Notice/` | 記録・削除の知らせのモデルと、保存の失敗が空き容量不足かの見分け |
| `FeatureModels/Shared/Notification/` | 通知の許可の窓口 |
| `FeatureModels/Shared/Period/` | 期間の範囲と月の始まりの文言 |
| `FeatureModels/Shared/Pro/` | Pro を買ったかと、購入の窓口。StoreKit の中身は AppFeature が渡す |
| `FeatureModels/Shared/SettingsParts/` | 設定の画面で使うモデル（Board・Hint・Icon・Input）。並べ替えと編集とアイコンの選びを受け持つ |
| `FeatureModels/Shared/Setup/` | 残りの設定とカスタマイズの項目と進み具合 |
| `FeatureModels/Shared/Stamp/` | スタンプを押した日の数え上げ |
| `Features/Screens/Entry/` | 記録の入力シート |
| `Features/Screens/Entry/Receipt/` | レシートを VisionKit で撮る画面と、読んでいる間のカード |
| `Features/Screens/Entry/Voice/` | 声の入力のカード・波形・終わるボタン・知らせ |
| `Features/Screens/Onboarding/` | 最初の設定のチュートリアル |
| `Features/Screens/Pro/` | Pro の画面 |
| `Features/Screens/Settings/` | 設定の項目ごとの画面。Menu は入口と、確かめ用のテストデータ（`#if DEBUG`） |
| `Features/Screens/Tabs/` | Assets・Home・Records・Review |
| `Features/Screens/WhatsNew/` | お知らせの版と機能の一覧と、それを並べるシート。`Model/` に版、`View/` にシートとカードとページ送り、`Parts/` に使い方のコマ |
| `Features/Shared/Bill/` | これからの引き落としの行・月のページ送りとタブ・見込みと確定の印と、その言葉 |
| `Features/Shared/DateChoice/` | 月の始まりの日を選ぶ部品 |
| `Features/Shared/FeatureArt/` | お知らせと Pro で機能を見せる絵（レシート・伝票・iPhone の枠・見本）と、縮める枠 |
| `Features/Shared/Notice/` | 記録・削除の知らせの帯と取り消し。ファイルの頭は、元の型ごとに分かれる |
| `Features/Shared/Notification/` | 通知の許可が無いときの帯と、許可の窓口を画面に渡す値 |
| `Features/Shared/Period/` | 期間のカード、期間を送る行と今に戻るボタン |
| `Features/Shared/Placeholder/` | タブで記録が無いときと読み込めないときの表示。設定の一覧が空なら `SettingsParts/Hint/` の `SettingsEmptyNote` を使う |
| `Features/Shared/Pro/` | 止めた所の下に出すカードと、Pro の窓口を画面に渡す値 |
| `Features/Shared/SettingsParts/` | 設定の画面で使う部品（Board・Drag・Hint・Icon・Input・Layout・Tile）。画面の上のヘッダーは `Layout/` に、持ち上げと置き場所の部品は `Drag/` に置く |
| `Features/Shared/Setup/` | 残りの設定の一覧と、項目から開く画面 |
| `Features/Shared/Stamp/` | 押したスタンプの数のカードと、押した日の一覧のシート |
| `Features/Shared/Wallet/` | 口座の役割ごとの、残高に添える言葉と額の色。資産のタブと設定の口座で使う |
| `Sync/` | CKSyncEngine で変更を送り受けする。財布の共有、共有シート、共有の受け入れも作る |
| `Tests/TestSupport/` | テストの補助。観測している値が変わるのを、上限の時間まで待つ |

画面ごとのフォルダは、[architecture-screens の「画面とフォルダ」](architecture-screens.md#-画面とフォルダ)にある。名前の決まりと、概念ごとの置き場所は、[architecture-naming](architecture-naming.md) にある。
