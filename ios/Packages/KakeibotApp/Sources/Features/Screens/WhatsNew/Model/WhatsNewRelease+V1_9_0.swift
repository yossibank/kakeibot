extension WhatsNewRelease {
    static let v1_9_0 = WhatsNewRelease(
        version: "1.9.0",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "envelope.open",
                title: "新しいふりかえり",
                shortTitle: "ふりかえり",
                lead: "今のペースと、締めたあとのレポートに分かれました",
                points: [
                    "今の期間は、いまのペースと月末の見込みを出します",
                    "締めた期間は、結果と次の一手をレポートにまとめます",
                    "次の一手は、次に締めた時に答え合わせします"
                ],
                note: "一手の理由は、iOS 26 以降で Apple Intelligence をオンにした端末で AI が書きます",
                steps: [
                    Step(scene: .review(.pace), caption: "いまのペースを見る"),
                    Step(scene: .review(.closing), caption: "締めのレポートを読む"),
                    Step(scene: .review(.goal), caption: "次の一手を確かめる")
                ],
                action: .review,
                actionTitle: "ふりかえりを見る"
            )
        ]
    )
}
