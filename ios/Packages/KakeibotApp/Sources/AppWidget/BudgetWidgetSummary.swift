import Core
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
