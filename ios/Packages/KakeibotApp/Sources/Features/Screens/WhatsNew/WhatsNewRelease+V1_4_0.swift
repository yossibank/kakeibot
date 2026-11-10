extension WhatsNewRelease {
    static let v1_4_0 = WhatsNewRelease(
        version: "1.4.0",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "calendar.badge.plus",
                title: "予定のお金",
                shortTitle: "予定",
                lead: "先の記録を含めた手元のお金が分かります",
                points: [
                    "明日以降の記録を含めた額を表示します",
                    "押すと予定の記録を日付順に見られます"
                ],
                steps: [
                    Step(scene: .planTab, caption: "「資産」を開く"),
                    Step(scene: .planButton, caption: "「予定を含めると」を押す"),
                    Step(scene: .planList, caption: "予定の記録が並ぶ")
                ],
                action: .assets,
                actionTitle: "資産を開く"
            ),
            Feature(
                systemImage: "creditcard",
                title: "引き落としの月",
                shortTitle: "引き落とし",
                lead: "これからの引き落としを月ごとに見られます",
                points: [
                    "指で横に送って月を切り替えられます",
                    "締め日までの見込みと確定が分かります"
                ],
                steps: [
                    Step(scene: .pagerCard, caption: "引き落としのカードを見る"),
                    Step(scene: .pagerSwipe, caption: "指で横に送る"),
                    Step(scene: .pagerNext, caption: "次の月の引き落とし")
                ],
                action: .assets,
                actionTitle: "資産を開く"
            ),
            Feature(
                systemImage: "wallet.bifold",
                title: "口座の種類",
                shortTitle: "口座",
                lead: "口座の種類を選びやすくしました",
                points: [
                    "3 つの組に分けて並べました",
                    "資産タブからカードの口座を作れます"
                ],
                steps: [
                    Step(scene: .walletAdd, caption: "負債の「＋」を押す"),
                    Step(scene: .walletKinds, caption: "組から種類を選ぶ"),
                    Step(scene: .walletMade, caption: "カードの口座ができる")
                ],
                action: .assets,
                actionTitle: "資産を開く"
            )
        ]
    )
}
