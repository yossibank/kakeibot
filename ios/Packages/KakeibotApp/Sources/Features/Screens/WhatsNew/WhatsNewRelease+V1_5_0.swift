extension WhatsNewRelease {
    static let v1_5_0 = WhatsNewRelease(
        version: "1.5.0",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "calendar",
                title: "月末の見込み",
                shortTitle: "見込み",
                lead: "月末に手元のお金がいくら残るか分かります",
                points: [
                    "固定費のこれからの回と予定の記録を足します",
                    "いちばん少ない日や足りなくなる日をお知らせします",
                    "振り返りタブにも「固定費あと・月末」を表示します"
                ],
                steps: [
                    Step(scene: .outlookTab, caption: "「資産」を開く"),
                    Step(scene: .outlookBlock, caption: "「月末の見込み」を押す"),
                    Step(scene: .outlookList, caption: "出入りが日付順に並ぶ")
                ],
                action: .assets,
                actionTitle: "資産を開く"
            )
        ]
    )
}
