import Core

public struct MonthOverview: Equatable, Sendable {
    public let list: EntryList?
    public let budgets: [Budget]
    public let recurrings: [Recurring]
    public let monthStartDay: MonthStartDay
    public let today: LocalDate

    public init(
        list: EntryList?,
        budgets: [Budget],
        recurrings: [Recurring],
        monthStartDay: MonthStartDay,
        today: LocalDate
    ) {
        self.list = list
        self.budgets = budgets
        self.recurrings = recurrings
        self.monthStartDay = monthStartDay
        self.today = today
    }
}

public extension MonthOverview {
    var month: YearMonth {
        today.periodMonth(startingOn: monthStartDay)
    }

    var period: ClosedRange<LocalDate> {
        month.period(startingOn: monthStartDay)
    }

    var monthExpense: Int {
        monthDays.reduce(0) { $0 + $1.expenseTotal }
    }

    var monthIncome: Int {
        monthDays.reduce(0) { $0 + $1.incomeTotal }
    }

    var todayExpense: Int {
        expense(on: today)
    }

    var yesterdayExpense: Int {
        expense(on: today.adding(days: -1))
    }

    var periodRecurrings: [PeriodRecurring] {
        let entries = list?.days
            .flatMap(\.entries)
            .filter { $0.recurringId != nil } ?? []

        return recurrings
            .flatMap { recurring in
                recurring
                    .dates(from: period.lowerBound, through: period.upperBound)
                    .compactMap { date in
                        let entry = entries.first { entry in
                            recurring.isRecorded(by: entry, on: date)
                        }

                        let amount = entry?.amount
                            ?? paidAmount(of: recurring, on: date)
                            ?? recurring.amount

                        guard entry != nil || amount > 0 else {
                            return nil
                        }

                        return PeriodRecurring(
                            date: date,
                            recurring: recurring,
                            entry: entry,
                            status: status(of: date, entry: entry),
                            amount: amount
                        )
                    }
            }
            .sorted { $0.date < $1.date }
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
            spent: monthExpense,
            upcoming: upcomingRecurringExpense,
            today: today,
            periodEnd: period.upperBound
        )
    }

    func moved(to day: LocalDate) -> MonthOverview {
        MonthOverview(
            list: list,
            budgets: budgets,
            recurrings: recurrings,
            monthStartDay: monthStartDay,
            today: day
        )
    }
}

private extension MonthOverview {
    var monthDays: [EntryDay] {
        list?.days.filter { period.contains($0.date) } ?? []
    }

    func expense(on date: LocalDate) -> Int {
        list?.days.first { $0.date == date }?.expenseTotal ?? 0
    }

    func paidAmount(
        of recurring: Recurring,
        on date: LocalDate
    ) -> Int? {
        list.map { list in
            let entries = list.days.flatMap(\.entries)
            return recurring.amount(paidOn: date, entries: entries)
        }
    }

    func status(
        of date: LocalDate,
        entry: Entry?
    ) -> PeriodRecurring.Status {
        if entry != nil {
            return .done
        }

        return date > today ? .upcoming : .missing
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
