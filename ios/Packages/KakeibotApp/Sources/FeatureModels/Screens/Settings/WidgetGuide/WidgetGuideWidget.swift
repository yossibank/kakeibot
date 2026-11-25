public enum WidgetGuideWidget: CaseIterable, Hashable, Sendable {
    case budget
    case quickRecord
}

public extension WidgetGuideWidget {
    var title: String {
        switch self {
        case .budget: "あといくら"
        case .quickRecord: "すぐ記録"
        }
    }

    var abilities: [WidgetGuidePlace.Ability] {
        switch self {
        case .budget:
            [
                WidgetGuidePlace.Ability(
                    systemImage: "gauge.with.needle",
                    title: "今月あといくら",
                    detail: "予算の残りと、今日の支出を出します"
                ),
                WidgetGuidePlace.Ability(
                    systemImage: "calendar",
                    title: "中は今週と今月も",
                    detail: "今週・今月の支出と、次の固定費を添えます"
                ),
                WidgetGuidePlace.Ability(
                    systemImage: "hand.tap",
                    title: "押すとホームへ",
                    detail: "押すと、アプリのホームを開きます"
                )
            ]

        case .quickRecord:
            [
                WidgetGuidePlace.Ability(
                    systemImage: "bolt",
                    title: "押すだけで記録",
                    detail: "テンプレートを押すと、アプリを開かずに記録します"
                ),
                WidgetGuidePlace.Ability(
                    systemImage: "arrow.uturn.backward",
                    title: "5 秒は取り消せる",
                    detail: "押し間違えたら、上に出る「取り消す」を押します"
                ),
                WidgetGuidePlace.Ability(
                    systemImage: "pencil",
                    title: "鉛筆の印は金額を入れる",
                    detail: "入力シートを開き、金額を入れて記録します"
                )
            ]
        }
    }
}
