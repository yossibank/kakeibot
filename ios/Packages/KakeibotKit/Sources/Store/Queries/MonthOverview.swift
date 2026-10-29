import Core

public struct MonthOverview: Equatable, Sendable {
    public let list: EntryList?
    public let budgets: [Budget]
    public let recurrings: [Recurring]
    public let monthStartDay: MonthStartDay
    public let today: LocalDate
    public let periodRecurrings: [PeriodRecurring]

    private let monthDays: [EntryDay]

    public init(
        list: EntryList?,
        budgets: [Budget],
        recurrings: [Recurring],
        monthStartDay: MonthStartDay,
        today: LocalDate
    ) {
        let month = today.periodMonth(startingOn: monthStartDay)
        let period = month.period(startingOn: monthStartDay)
        let entries = list?.days.flatMap(\.entries)

        self.list = list
        self.budgets = budgets
        self.recurrings = recurrings
        self.monthStartDay = monthStartDay
        self.today = today

        self.periodRecurrings = Self.periodRecurrings(
            of: recurrings,
            in: period,
            entries: entries,
            today: today
        )

        self.monthDays = list?.days.filter { period.contains($0.date) } ?? []
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
        list?.days.filter { range.contains($0.date) }.reduce(0) { $0 + $1.expenseTotal } ?? 0
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
    static func periodRecurrings(
        of recurrings: [Recurring],
        in period: ClosedRange<LocalDate>,
        entries: [Entry]?,
        today: LocalDate
    ) -> [PeriodRecurring] {
        let recorded = entries?.filter { $0.recurringId != nil } ?? []

        return recurrings
            .flatMap { recurring in
                recurring
                    .occurrences(from: period.lowerBound, through: period.upperBound)
                    .compactMap { occurrence in
                        let date = occurrence.date

                        let entry = recorded.first { entry in
                            recurring.isRecorded(by: entry, scheduled: occurrence.scheduled)
                        }

                        let amount = entry?.amount
                            ?? entries.map { recurring.amount(paidOn: date, entries: $0) }
                            ?? recurring.amount

                        guard entry != nil || amount > 0 else {
                            return nil
                        }

                        let state = status(
                            of: date,
                            entry: entry,
                            recurring: recurring,
                            today: today
                        )

                        return PeriodRecurring(
                            date: date,
                            recurring: recurring,
                            entry: entry,
                            status: state,
                            amount: amount
                        )
                    }
            }
            .sorted { $0.date < $1.date }
    }

    static func status(
        of date: LocalDate,
        entry: Entry?,
        recurring: Recurring,
        today: LocalDate
    ) -> PeriodRecurring.Status {
        if entry != nil {
            return .done
        }

        if date > today {
            return .upcoming
        }

        let isGenerated = recurring.generatedUntil.map { date <= $0 } ?? false

        return date == today && !isGenerated ? .upcoming : .missing
    }

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
