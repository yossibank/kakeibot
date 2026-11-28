import FeatureModels

extension WhatsNewRelease {
    static let v1_10_0 = WhatsNewRelease(
        version: "1.10.0",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "textformat",
                title: "新しい字体",
                shortTitle: "字体",
                lead: "教科書や太明朝など、4 つの字体が増えました",
                points: [
                    "教科書・太明朝・太ゴシック・かな明朝を足しました",
                    "手書きを含む 5 つの字体は、選んだ時に読み込みます",
                    "一度読み込めば、次からはすぐに使えます"
                ],
                note: "明朝とゴシックのほかは、Pro で使えます",
                steps: [
                    Step(scene: .font(.choose), caption: "字体を選ぶ"),
                    Step(scene: .font(.loading), caption: "読み込みを待つ"),
                    Step(scene: .font(.ready), caption: "アプリ全体が変わる")
                ],
                action: .setup(.themeStyle),
                actionTitle: "文字を選ぶ"
            ),
            Feature(
                systemImage: "square.grid.3x3",
                title: "増えたアイコン",
                shortTitle: "アイコン",
                lead: "食べ物・機器・健康・お金の絵柄が増えました",
                points: [
                    "イヤホンや腕時計など、身の回りの機器を足しました",
                    "薬や体温計など、健康の絵柄を足しました",
                    "ポイントや暗号資産など、お金の絵柄を足しました"
                ],
                steps: [
                    Step(scene: .icon(.row), caption: "「カテゴリ」を開く"),
                    Step(scene: .icon(.button), caption: "アイコンを押す"),
                    Step(scene: .icon(.added), caption: "増えた絵柄から選ぶ")
                ],
                action: .setup(.categories),
                actionTitle: "カテゴリを開く"
            )
        ]
    )
}
