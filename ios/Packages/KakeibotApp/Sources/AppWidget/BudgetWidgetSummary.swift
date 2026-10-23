import Core
import DesignSystem
import Store

struct BudgetWidgetSummary: Hashable, Sendable {
    let usage: BudgetUsage?
    let pace: BudgetPace?
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

    struct Focus: Hashable {
        let title: String
        let text: String
        let isShort: Bool
    }

    var focus: Focus {
        guard let pace else {
            let text = AmountText.text(todayExpense)

            return Focus(title: "今日の支出", text: text, isShort: false)
        }

        return Focus(title: "このペースだと", text: pace.leftText, isShort: pace.isShort)
    }

    init(
        _ overview: MonthOverview,
        weekStart: Weekday
    ) {
        let week = overview.today.week(startingOn: weekStart)

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
            pace: overview.budgetPace,
            monthExpense: overview.monthExpense,
            todayExpense: overview.todayExpense,
            yesterdayExpense: overview.yesterdayExpense,
            weekExpense: overview.expense(in: week),
            nextRecurring: next
        )
    }

    static func sample(on today: LocalDate) -> BudgetWidgetSummary {
        let periodEnd = today.adding(days: 8)
        let period = today.adding(days: -21)...periodEnd

        let usage = BudgetUsage(
            budget: 90000,
            spent: 58000,
            today: today,
            periodEnd: periodEnd
        )

        let pace = BudgetPace(
            budget: usage.budget,
            spent: usage.spent,
            fixedSpent: 30000,
            upcoming: 0,
            today: today,
            period: period
        )

        let next = NextRecurring(
            title: "家賃",
            date: today.adding(days: 3),
            amount: 80000
        )

        return BudgetWidgetSummary(
            usage: usage,
            pace: pace,
            monthExpense: usage.spent,
            todayExpense: 1120,
            yesterdayExpense: 2300,
            weekExpense: 8400,
            nextRecurring: next
        )
    }
}
