import Core

public extension BudgetUsage {
    var remainingTitle: String {
        isOver ? "予算オーバー" : "今月あといくら"
    }

    var remainingAmountText: String {
        AmountText.text(abs(remaining))
    }

    var remainingText: String {
        if isOver {
            return "オーバー \(AmountText.text(-remaining))"
        }

        return "残り \(AmountText.text(remaining))"
    }

    var warningText: String? {
        isNearLimit ? "予算の 8 割を使いました" : nil
    }
}
