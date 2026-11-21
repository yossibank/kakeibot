extension WhatsNewRelease {
    static let v1_8_1 = WhatsNewRelease(
        version: "1.8.1",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "chart.bar.xaxis",
                title: "AI 分析レポート",
                shortTitle: "分析",
                lead: "分析は、振り返りの金の帯から開きます",
                points: [
                    "期間の下の「AI 分析レポート」を押すと開きます",
                    "左右にスワイプして、ほかの期間の分析も読めます",
                    "記録が変わると、次に開いた時に新しくなります"
                ],
                note: "iOS 26 以降で、Apple Intelligence をオンにした端末で使えます",
                steps: [
                    Step(scene: .analysisBanner, caption: "金の帯から開く"),
                    Step(scene: .analysisReason, caption: "増えた理由を見る"),
                    Step(scene: .analysisSummary, caption: "AI のまとめを読む")
                ],
                action: .review,
                actionTitle: "振り返りを見る"
            )
        ]
    )
}
