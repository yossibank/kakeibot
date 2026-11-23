import Core

public extension BudgetUsage {
    var remainingTitle: String {
        isOver ? "予算オーバー" : "今月あといくら"
    }

    var remainingAmountText: String {
        Yen.text(abs(remaining))
    }

    var remainingText: String {
        if isOver {
            return "オーバー \(Yen.text(-remaining))"
        }

        return "残り \(Yen.text(remaining))"
    }

    var budgetText: String {
        let base = "予算 \(Yen.text(baseBudget))"

        if carryover > 0 {
            return "\(base) ＋ 繰越 \(Yen.text(carryover))"
        }

        if carryover < 0 {
            return "\(base) − 繰越 \(Yen.text(-carryover))"
        }

        return base
    }

    var carryoverText: String {
        let sign = carryover < 0 ? "−" : "＋"
        return "繰越 \(sign)\(Yen.text(abs(carryover)))"
    }

    var warningText: String? {
        isNearLimit ? "予算の 8 割を使いました" : nil
    }
}
