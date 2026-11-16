extension WhatsNewRelease {
    static let v1_7_0 = WhatsNewRelease(
        version: "1.7.0",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "ipad",
                title: "iPad で使える",
                shortTitle: "iPad",
                lead: "広い画面で、家計をひと目で見られます",
                points: [
                    "ホーム・振り返り・資産を 2 列で並べます",
                    "キーボードの数字で金額を打てます",
                    "Pro の同期で、iPhone と同じ記録を使えます"
                ],
                steps: [
                    Step(scene: .padHome, caption: "ホームを 2 列で見渡す"),
                    Step(scene: .padReview, caption: "振り返りを並べて見る"),
                    Step(scene: .padKeyboard, caption: "キーボードで金額を打つ")
                ],
                action: nil,
                actionTitle: ""
            )
        ]
    )
}
