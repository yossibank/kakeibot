import FeatureModels

extension WhatsNewRelease {
    static let v1_3_0 = WhatsNewRelease(
        version: "1.3.0",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "calendar.badge.clock",
                title: "借入の返済の回数",
                shortTitle: "返済",
                lead: "回数を入れると、返し終わるまでが分かります",
                points: [
                    "最後の回の額を残高から計算します",
                    "返す総額と終わりの月が分かります"
                ],
                steps: [
                    Step(scene: .loan(.count), caption: "「回数」を押す"),
                    Step(scene: .loan(.last), caption: "回数を入れる"),
                    Step(scene: .loan(.total), caption: "総額と終わりが出る")
                ],
                action: .setup(.recurrings),
                actionTitle: "固定費を開く"
            ),
            Feature(
                systemImage: "square.grid.2x2",
                title: "アイコンと絵文字",
                shortTitle: "アイコン",
                lead: "カテゴリなどに使える絵柄が増えました",
                points: [
                    "暮らしや趣味の絵柄を選べます",
                    "食べ物などの絵文字も選べます"
                ],
                steps: [
                    Step(scene: .icon(.row), caption: "「カテゴリ」を開く"),
                    Step(scene: .icon(.button), caption: "アイコンを押す"),
                    Step(scene: .icon(.grid), caption: "増えた絵柄から選ぶ")
                ],
                action: .setup(.categories),
                actionTitle: "カテゴリを開く"
            )
        ]
    )
}
