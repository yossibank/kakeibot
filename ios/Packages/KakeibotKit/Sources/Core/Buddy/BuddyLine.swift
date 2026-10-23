public struct BuddyLine: Hashable, Sendable {
    public let text: String

    public init(_ text: String) {
        self.text = text
    }
}

public extension BuddyLine {
    static func budget(_ usage: BudgetUsage?) -> BuddyLine {
        guard let usage else {
            return BuddyLine("予算を決めると、使いすぎを一緒に見守ります")
        }

        if usage.isOver {
            return BuddyLine("予算を超えました。ここから立て直しましょう")
        }

        if usage.isNearLimit {
            return BuddyLine("予算まであと少しです。気をつけましょう")
        }

        if usage.spent * 2 >= usage.budget {
            return BuddyLine("半分を過ぎました。このペースでいきましょう")
        }

        return BuddyLine("いい調子です。この調子でいきましょう")
    }

    static func reward(count: Int) -> BuddyLine {
        switch count {
        case ...0:
            BuddyLine("できたことがあれば、付けてみましょう")
        case 1:
            BuddyLine("達成しました。えらいです")
        default:
            BuddyLine("\(count) つも達成しました。すごいです")
        }
    }
}
