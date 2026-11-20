extension WhatsNewRelease {
    static let v1_8_0 = WhatsNewRelease(
        version: "1.8.0",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "chart.bar.doc.horizontal",
                title: "振り返りの分析",
                shortTitle: "分析",
                lead: "支出が増えた理由を、ひと目で見られます",
                points: [
                    "「グラフ / 分析」で、分析に切り替えます",
                    "増えた理由と、カテゴリの動きを並べます",
                    "対応する端末では、AI のまとめも出します"
                ],
                steps: [
                    Step(scene: .analysisSwitch, caption: "分析に切り替える"),
                    Step(scene: .analysisReason, caption: "増えた理由を見る"),
                    Step(scene: .analysisSummary, caption: "AI のまとめを読む")
                ],
                action: .review,
                actionTitle: "振り返りを見る"
            )
        ]
    )
}
