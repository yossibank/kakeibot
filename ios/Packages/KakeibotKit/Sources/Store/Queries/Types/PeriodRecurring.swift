import Core

public struct PeriodRecurring: Hashable, Sendable {
    public let date: LocalDate
    public let recurring: Recurring
    public let entry: Entry?
    public let status: Status
    public let amount: Int

    public init(
        date: LocalDate,
        recurring: Recurring,
        entry: Entry?,
        status: Status,
        amount: Int
    ) {
        self.date = date
        self.recurring = recurring
        self.entry = entry
        self.status = status
        self.amount = amount
    }
}

public extension PeriodRecurring {
    enum Status: Hashable, Sendable {
        case done
        case upcoming
        case missing
    }
}

public extension PeriodRecurring {
    static func all(
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

                        let entry = recurring.record(of: occurrence, in: recorded)

                        let amount = entry?.amount
                            ?? entries.map { recurring.amount(paidOn: date, entries: $0) }
                            ?? recurring.scheduledAmount(paidOn: date)

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
}

private extension PeriodRecurring {
    static func status(
        of date: LocalDate,
        entry: Entry?,
        recurring: Recurring,
        today: LocalDate
    ) -> Status {
        if entry != nil {
            return .done
        }

        if date > today {
            return .upcoming
        }

        let isGenerated = recurring.generatedUntil.map { date <= $0 } ?? false

        return date == today && !isGenerated
            ? .upcoming
            : .missing
    }
}
