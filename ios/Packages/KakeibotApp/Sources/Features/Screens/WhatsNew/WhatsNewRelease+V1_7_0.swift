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
                    Step(scene: .pad(.home), caption: "ホームを 2 列で見渡す"),
                    Step(scene: .pad(.review), caption: "振り返りを並べて見る"),
                    Step(scene: .pad(.keyboard), caption: "キーボードで金額を打つ")
                ],
                action: nil,
                actionTitle: ""
            ),
            Feature(
                systemImage: "calendar.badge.clock",
                title: "予定の固定費",
                shortTitle: "予定",
                lead: "月末までの固定費を先に見られます",
                points: [
                    "明日から月末までの固定費を、日付ごとに並べます",
                    "「これから」と「これまで」で、今日の前後を分けます",
                    "押すと、その固定費を開けます"
                ],
                steps: [
                    Step(scene: .upcoming(.captions), caption: "これからの日が上に並ぶ"),
                    Step(scene: .upcoming(.day), caption: "日付ごとに固定費を見る"),
                    Step(scene: .upcoming(.open), caption: "押して固定費を開く")
                ],
                action: .records,
                actionTitle: "記録を見る"
            ),
            Feature(
                systemImage: "square.grid.2x2",
                title: "すぐ記録のウィジェット",
                shortTitle: "ウィジェット",
                lead: "ホーム画面から色で選んで記録できます",
                points: [
                    "テンプレートに、カテゴリの色のアイコンを付けます",
                    "大きいウィジェットでは、今日の記録も色で見分けられます",
                    "「レシート」から、読み取りをすぐ始められます"
                ],
                steps: [
                    Step(scene: .widget(.tiles), caption: "カテゴリの色で選ぶ"),
                    Step(scene: .widget(.receipt), caption: "「レシート」を押す"),
                    Step(scene: .receipt(.camera), caption: "そのまま読み取りが始まる")
                ],
                action: nil,
                actionTitle: ""
            )
        ]
    )
}
