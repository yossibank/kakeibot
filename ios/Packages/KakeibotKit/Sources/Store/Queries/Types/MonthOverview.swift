import Core

public struct MonthOverview: Equatable, Sendable {
    public let list: EntryList?
    public let budgets: [Budget]
    public let recurrings: [Recurring]
    public let monthStartDay: MonthStartDay
    public let carryoverFrom: YearMonth?
    public let today: LocalDate
    public let month: YearMonth
    public let period: ClosedRange<LocalDate>
    public let periodRecurrings: [PeriodRecurring]
    public let monthDays: [EntryDay]
    public let monthExpense: Int
    public let monthIncome: Int
    public let budgetCarryover: Int

    public init(
        list: EntryList?,
        budgets: [Budget],
        recurrings: [Recurring],
        monthStartDay: MonthStartDay,
        carryoverFrom: YearMonth? = nil,
        today: LocalDate
    ) {
        let month = today.periodMonth(startingOn: monthStartDay)
        let period = month.period(startingOn: monthStartDay)
        let entries = list?.entries

        self.list = list
        self.budgets = budgets
        self.recurrings = recurrings
        self.monthStartDay = monthStartDay
        self.carryoverFrom = carryoverFrom
        self.today = today
        self.month = month
        self.period = period

        self.periodRecurrings = PeriodRecurring.all(
            of: recurrings,
            in: period,
            entries: entries,
            today: today
        )

        self.monthDays = list?.days.within(period) ?? []
        self.monthExpense = monthDays.expenseTotal
        self.monthIncome = monthDays.incomeTotal

        self.budgetCarryover = list?.budgetCarryover(
            budgets: budgets,
            from: carryoverFrom,
            into: month,
            startingOn: monthStartDay
        ) ?? 0
    }
}

public extension MonthOverview {
    var todayExpense: Int {
        expense(on: today)
    }

    var yesterdayExpense: Int {
        let yesterday = today.adding(days: -1)
        return expense(on: yesterday)
    }

    var recurringExpense: Int {
        recurringTotal(of: .expense)
    }

    var recurringIncome: Int {
        recurringTotal(of: .income)
    }

    var paidRecurringExpense: Int {
        recurringTotal(of: .expense) { $0 == .done }
    }

    var upcomingRecurringExpense: Int {
        recurringTotal(of: .expense) { $0 == .upcoming }
    }

    var paidRecurringRatio: Double {
        guard recurringExpense > 0 else {
            return 0
        }

        let ratio = Double(paidRecurringExpense) / Double(recurringExpense)

        return min(ratio, 1)
    }

    var budgetUsage: BudgetUsage? {
        guard let budget = budgets.amount(for: nil, in: month) else {
            return nil
        }

        return BudgetUsage(
            budget: budget,
            carryover: budgetCarryover,
            spent: monthExpense,
            today: today,
            periodEnd: period.upperBound
        )
    }

    var nextRecurringExpense: PeriodRecurring? {
        periodRecurrings.first { item in
            item.recurring.type == .expense && item.status == .upcoming
        }
    }

    func expense(in range: ClosedRange<LocalDate>) -> Int {
        list?.days.within(range).expenseTotal ?? 0
    }

    func moved(to day: LocalDate) -> MonthOverview {
        MonthOverview(
            list: list,
            budgets: budgets,
            recurrings: recurrings,
            monthStartDay: monthStartDay,
            carryoverFrom: carryoverFrom,
            today: day
        )
    }
}

private extension MonthOverview {
    func expense(on date: LocalDate) -> Int {
        list?.days.first { $0.date == date }?.expenseTotal ?? 0
    }

    func recurringTotal(
        of type: Entry.Kind,
        where isIncluded: (PeriodRecurring.Status) -> Bool = { _ in true }
    ) -> Int {
        periodRecurrings
            .filter { $0.recurring.type == type && isIncluded($0.status) }
            .reduce(0) { $0 + $1.amount }
    }
}
