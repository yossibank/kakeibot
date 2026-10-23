import Core

public extension BudgetUsage {
    var remainingText: String {
        if isOver {
            return "\(AmountText.text(-remaining)) 超え"
        }

        return "残り \(AmountText.text(remaining))"
    }

    var warningText: String? {
        if isOver {
            return "予算を超えています"
        }

        return isNearLimit ? "予算の 8 割を使いました" : nil
    }
}
