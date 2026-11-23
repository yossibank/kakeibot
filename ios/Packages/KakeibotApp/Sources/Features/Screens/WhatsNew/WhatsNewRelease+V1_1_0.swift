extension WhatsNewRelease {
    static let v1_1_0 = WhatsNewRelease(
        version: "1.1.0",
        month: "2026年11月",
        features: [
            Feature(
                systemImage: "doc.text.viewfinder",
                title: "レシートを撮って記録",
                shortTitle: "レシート",
                lead: "撮るだけで、品目まで入ります",
                points: [
                    "品目・合計・日付・店名を読み取ります",
                    "合計が合わない品目には色が付きます",
                    "直した品名を、店ごとに覚えます"
                ],
                note: "iOS 26 以降で Apple Intelligence をオンにすると、品目をより正しく読めます",
                steps: [
                    Step(scene: .receipt(.button), caption: "「レシート」を押す"),
                    Step(scene: .receipt(.camera), caption: "レシートを撮る"),
                    Step(scene: .receipt(.items), caption: "品目が入る")
                ],
                action: .entry,
                actionTitle: "入力シートを開く"
            ),
            Feature(
                systemImage: "list.bullet.rectangle",
                title: "記録の品目",
                shortTitle: "品目",
                lead: "1 つの記録に、買った物を並べられます",
                points: [
                    "品目ごとに金額と個数を入れられます",
                    "8% と 10% の消費税を分けて表示します",
                    "記録の一覧で品名を探せます"
                ],
                steps: [
                    Step(scene: .items(.add), caption: "「＋ 品目」を押す"),
                    Step(scene: .items(.slip), caption: "品名と金額を入れる"),
                    Step(scene: .items(.list), caption: "税率ごとに並ぶ")
                ],
                action: .entry,
                actionTitle: "入力シートを開く"
            ),
            Feature(
                systemImage: "arrow.uturn.forward.circle",
                title: "予算の繰越",
                shortTitle: "繰越",
                lead: "余った予算を、次の期間に回せます",
                points: [
                    "残りは次の予算に足します",
                    "使いすぎた分は次の予算から引きます"
                ],
                steps: [
                    Step(scene: .carryover(.toggle), caption: "繰り越すにする"),
                    Step(scene: .carryover(.left), caption: "残りが出る"),
                    Step(scene: .carryover(.next), caption: "次の予算に足す")
                ],
                action: .setup(.budget),
                actionTitle: "予算を開く"
            ),
            Feature(
                systemImage: "calendar.badge.clock",
                title: "月の始まりを平日に",
                shortTitle: "月の始まり",
                lead: "給料日が休みの月も、合わせて数えられます",
                points: [
                    "土日・祝日なら、前か次の平日にずらします",
                    "期間と予算も、ずらした日から数えます"
                ],
                steps: [
                    Step(scene: .monthStart(.day), caption: "始まりの日を選ぶ"),
                    Step(scene: .monthStart(.shift), caption: "「前の平日」を押す"),
                    Step(scene: .monthStart(.period), caption: "期間がずれる")
                ],
                action: .setup(.monthStart),
                actionTitle: "月の始まりを開く"
            )
        ]
    )
}
