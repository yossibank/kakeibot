public struct BuddyLine: Hashable, Sendable {
    public let mood: BuddyMood
    public let text: String

    public init(
        mood: BuddyMood,
        text: String
    ) {
        self.mood = mood
        self.text = text
    }
}

public extension BuddyLine {
    static func budget(_ usage: BudgetUsage?) -> BuddyLine {
        guard let usage else {
            return BuddyLine(
                mood: .calm,
                text: "予算を決めると、使いすぎを一緒に見守ります"
            )
        }

        if usage.isOver {
            return BuddyLine(
                mood: .sad,
                text: "予算を超えました。ここから立て直しましょう"
            )
        }

        if usage.isNearLimit {
            return BuddyLine(
                mood: .worried,
                text: "予算まであと少しです。気をつけましょう"
            )
        }

        if usage.spent * 2 >= usage.budget {
            return BuddyLine(
                mood: .calm,
                text: "半分を過ぎました。このペースでいきましょう"
            )
        }

        return BuddyLine(
            mood: .smile,
            text: "いい調子です。この調子でいきましょう"
        )
    }

    static func reward(count: Int) -> BuddyLine {
        switch count {
        case ...0:
            BuddyLine(
                mood: .calm,
                text: "できたことがあれば、付けてみましょう"
            )
        case 1:
            BuddyLine(
                mood: .cheer,
                text: "達成しました。えらいです"
            )
        default:
            BuddyLine(
                mood: .cheer,
                text: "\(count) つも達成しました。すごいです"
            )
        }
    }
}
