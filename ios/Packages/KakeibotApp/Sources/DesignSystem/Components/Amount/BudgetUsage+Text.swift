import Core

public extension BudgetUsage {
    var remainingText: String {
        if isOver {
            return "\(AmountText.text(-remaining)) 超え"
        }

        return "残り \(AmountText.text(remaining))"
    }
}
