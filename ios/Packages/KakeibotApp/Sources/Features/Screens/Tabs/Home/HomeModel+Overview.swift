import Core
import Store

public extension HomeModel {
    var month: YearMonth {
        overview.month
    }

    var period: ClosedRange<LocalDate> {
        overview.period
    }

    var monthRangeText: String {
        PeriodText.range(period)
    }

    var monthExpense: Int {
        overview.monthExpense
    }

    var periodRecurrings: [PeriodRecurring] {
        overview.periodRecurrings
    }

    var recurringExpense: Int {
        overview.recurringExpense
    }

    var recurringIncome: Int {
        overview.recurringIncome
    }

    var paidRecurringExpense: Int {
        overview.paidRecurringExpense
    }

    var upcomingRecurringExpense: Int {
        overview.upcomingRecurringExpense
    }

    var paidRecurringRatio: Double {
        overview.paidRecurringRatio
    }

    var monthIncome: Int {
        overview.monthIncome
    }

    var todayExpense: Int {
        overview.todayExpense
    }

    var yesterdayExpense: Int {
        overview.yesterdayExpense
    }

    var middleTitle: String {
        budgetUsage == nil ? "昨日の支出" : "今月の支出"
    }

    var middleAmount: Int {
        budgetUsage == nil ? yesterdayExpense : monthExpense
    }

    var budgetUsage: BudgetUsage? {
        overview.budgetUsage
    }
}
