import Core
import DesignSystem
import Store

struct BudgetWidgetSummary: Hashable, Sendable {
    let usage: BudgetUsage?
    let monthExpense: Int
    let todayExpense: Int
    let yesterdayExpense: Int
}

extension BudgetWidgetSummary {
    init(_ overview: MonthOverview) {
        self.init(
            usage: overview.budgetUsage,
            monthExpense: overview.monthExpense,
            todayExpense: overview.todayExpense,
            yesterdayExpense: overview.yesterdayExpense
        )
    }

    static func sample(on today: LocalDate) -> BudgetWidgetSummary {
        let usage = BudgetUsage(
            budget: 90000,
            spent: 58000,
            today: today,
            periodEnd: today.adding(days: 8)
        )

        return BudgetWidgetSummary(
            usage: usage,
            monthExpense: usage.spent,
            todayExpense: 1120,
            yesterdayExpense: 2300
        )
    }
}

extension BudgetWidgetSummary {
    struct Today: Hashable {
        let title: String
        let text: String
        let isOver: Bool
    }

    var today: Today {
        guard let usage else {
            let text = AmountText.text(todayExpense)

            return Today(title: "今日の支出", text: text, isOver: false)
        }

        if usage.isOver {
            return Today(title: "今月", text: usage.remainingText, isOver: true)
        }

        let left = usage.todayRemaining(spentToday: todayExpense)

        guard left < 0 else {
            let text = AmountText.text(left)

            return Today(title: "今日あと", text: text, isOver: false)
        }

        let text = "\(AmountText.text(-left)) 超え"

        return Today(title: "今日", text: text, isOver: true)
    }
}
