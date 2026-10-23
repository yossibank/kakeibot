import Core

public extension BudgetPace {
    var leftText: String {
        if isShort {
            return "\(AmountText.text(-projectedLeft)) 足りません"
        }

        return "\(AmountText.text(projectedLeft)) 余ります"
    }
}
