# KakeibotApp のフォルダ

> [!NOTE]
> KakeibotApp のフォルダの木と、フォルダごとの中身が分かる。
> 依存の向きと KakeibotKit は [architecture-packages](architecture-packages.md) にある。

## 📂 フォルダの中身

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
│   │   │   ├── Main/
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
│   │       ├── Model/
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
| `AppFeature/App/` | アプリの入口と起動、起動の印の動き、入力の準備。Pro が無くなったら同期を止める |
| `AppFeature/Bridge/` | Pro の購入を StoreKit で、iCloud のアカウントと共有の参加者を CloudKit で読む。`ScenePhase` をモデルの型に変える |
| `AppFeature/Main/` | 4 つのタブと入力シートなどのシートを組む |
| `AppWidget/Intents/` | すぐ記録の記録と取り消し、コントロールの「記録する」 |
| `AppWidget/Shared/` | ウィジェットをまたいで使う読み出し・書体・テーマ・タイムライン |
| `AppWidget/Widgets/` | ウィジェットごとのフォルダ。コントロールの「記録する」は `EntryControl/` |
| `FeatureModels/` | 画面のモデルと、モデルが使う値の型・文言・読み取り。フォルダは `Features/` と同じ形にする |
| `FeatureModels/Screens/Entry/` | 記録の入力シートのモデル |
| `FeatureModels/Screens/Entry/Receipt/` | レシートを Vision と Foundation Models で読む |
| `FeatureModels/Screens/Entry/Voice/` | 声を SpeechAnalyzer で聞き、Foundation Models でカテゴリと口座を選ぶ |
| `FeatureModels/Screens/Main/` | 入口の `MainView` のモデルと、レビューのお願い。画面は `AppFeature/Main/` にある |
| `FeatureModels/Screens/Pro/` | Pro の購入のモデル |
| `FeatureModels/Screens/Settings/Menu/` | 設定の入口のモデルと、確かめ用のテストデータ（`#if DEBUG`） |
| `FeatureModels/Shared/Bill/` | これからの引き落としを月のページに分ける |
| `FeatureModels/Shared/DateChoice/` | 休日のずらしと曜日の表示の名前 |
| `FeatureModels/Shared/EntryList/` | 記録の一覧の検索と絞り込み、一覧の行に出す値、記録で選べるカテゴリ・タグ・アイコンと、口座の見出しの言葉 |
| `FeatureModels/Shared/Model/` | 画面のモデルの見張り（失敗で見張り直す）、読み込みと知らせの状態、文言に出す端末の名前（iPhone か iPad）。設定を失敗で戻す形、時計と待ち、値を覚える `Derived`・`DerivedTable` も置く |
| `FeatureModels/Shared/Model/` の `ScreenOutcome` | 保存できた・消した、の結果をモデルの `state` に置く型 |
| `FeatureModels/Shared/Model/` の `ScreenParts` | DB と時計と待ち（`ScreenWait`）を包んで、画面からモデルへ渡す型。中の DB は `FeatureModels` だけが読む |
| `FeatureModels/Shared/Notice/` | 記録・削除の知らせのモデルと、削除の取り消し（`DeletionUndo`）。保存の失敗が空き容量不足かの見分けも置く |
| `FeatureModels/Shared/Notification/` | 通知の許可の窓口 |
| `FeatureModels/Shared/Period/` | 期間の範囲と月の始まりの文言 |
| `FeatureModels/Shared/Pro/` | Pro を買ったか・購入の窓口・案内のモデル。StoreKit の中身は AppFeature が渡す |
| `FeatureModels/Shared/SettingsParts/` | 設定の画面で使うモデル（Board・Hint・Icon・Input）。並べ替え・編集・アイコンの選びと、説明カードを閉じたかを受け持つ |
| `FeatureModels/Shared/Setup/` | 残りの設定とカスタマイズの項目と進み具合 |
| `FeatureModels/Shared/Stamp/` | スタンプを押した日の数え上げ |
| `Features/Screens/Entry/` | 記録の入力シート |
| `Features/Screens/Entry/Receipt/` | レシートを VisionKit で撮る画面と、読んでいる間のカード |
| `Features/Screens/Entry/Slip/` | 入力シートの紙のカード（`EntrySlip`）と、その寸法と色、メモの行（`EntrySlipMemoRow`） |
| `Features/Screens/Entry/Voice/` | 声の入力のカード・波形・終わるボタン・知らせ |
| `Features/Screens/Onboarding/` | 最初の設定のチュートリアル |
| `Features/Screens/Pro/` | Pro の画面 |
| `Features/Screens/Settings/` | 設定の項目ごとの画面。Menu は入口 |
| `Features/Screens/Tabs/` | Assets・Home・Records・Review |
| `Features/Screens/WhatsNew/` | お知らせの版と機能の一覧と、それを並べるシート。`Model/` に版とモデル、`View/` にシートとカードとページ送り、`Parts/` に使い方のコマ |
| `Features/Shared/Bill/` | これからの引き落としの行・月のタブ・見込みと確定の印と、その言葉 |
| `Features/Shared/DateChoice/` | 月の始まりの日を選ぶ部品 |
| `Features/Shared/FeatureArt/` | お知らせと Pro で機能を見せる絵（レシート・伝票・iPhone の枠・見本）と、縮める枠 |
| `Features/Shared/Model/` | モデルが `state` に置いた結果の変化を、画面が受ける modifier と、タブの外枠（`tabScreen`） |
| `Features/Shared/Notice/` | 記録・削除の知らせの帯と、取り消しの知らせ（`undoNotice`）。ファイルの頭は、元の型ごとに分かれる |
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
