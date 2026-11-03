import Core
import Store

struct BudgetWidgetSummary: Hashable, Sendable {
    let usage: BudgetUsage?
    let monthExpense: Int
    let todayExpense: Int
    let yesterdayExpense: Int
    let weekExpense: Int
    let nextRecurring: NextRecurring?
}

extension BudgetWidgetSummary {
    struct NextRecurring: Hashable, Sendable {
        let title: String
        let date: LocalDate
        let amount: Int
    }

    init(
        _ overview: MonthOverview,
        weekStart: Weekday
    ) {
        let week = overview.today.week(startingOn: weekStart)
        let weekExpense = overview.expense(in: week)

        let next = overview.nextRecurringExpense.map { item in
            let title = overview.list?.title(of: item.recurring) ?? "固定費"

            return NextRecurring(
                title: title,
                date: item.date,
                amount: item.amount
            )
        }

        self.init(
            usage: overview.budgetUsage,
            monthExpense: overview.monthExpense,
            todayExpense: overview.todayExpense,
            yesterdayExpense: overview.yesterdayExpense,
            weekExpense: weekExpense,
            nextRecurring: next
        )
    }

    static func sample(on today: LocalDate) -> BudgetWidgetSummary {
        let periodEnd = today.adding(days: 8)
        let nextDate = today.adding(days: 3)

        let usage = BudgetUsage(
            budget: 90000,
            spent: 58000,
            today: today,
            periodEnd: periodEnd
        )

        let next = NextRecurring(
            title: "家賃",
            date: nextDate,
            amount: 80000
        )

        return BudgetWidgetSummary(
            usage: usage,
            monthExpense: usage.spent,
            todayExpense: 1120,
            yesterdayExpense: 2300,
            weekExpense: 8400,
            nextRecurring: next
        )
    }
}
