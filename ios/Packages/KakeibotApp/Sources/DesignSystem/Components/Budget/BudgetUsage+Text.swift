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

    var budgetText: String {
        let base = "予算 \(AmountText.text(baseBudget))"

        if carryover > 0 {
            return "\(base) ＋ 繰越 \(AmountText.text(carryover))"
        }

        if carryover < 0 {
            return "\(base) − 繰越 \(AmountText.text(-carryover))"
        }

        return base
    }

    var carryoverText: String {
        let sign = carryover < 0 ? "−" : "＋"
        return "繰越 \(sign)\(AmountText.text(abs(carryover)))"
    }

    var warningText: String? {
        isNearLimit ? "予算の 8 割を使いました" : nil
    }
}
