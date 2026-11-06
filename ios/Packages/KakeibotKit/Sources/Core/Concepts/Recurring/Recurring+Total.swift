public extension Recurring {
    func record(
        of occurrence: Occurrence,
        in entries: [Entry]
    ) -> Entry? {
        entries.first { entry in
            isRecorded(by: entry, scheduled: occurrence.scheduled)
        }
    }
}

public extension [Recurring] {
    func total(
        of type: Entry.Kind,
        in range: ClosedRange<LocalDate>
    ) -> Int {
        filter { $0.type == type }.reduce(0) { sum, recurring in
            let dates = recurring.dates(from: range.lowerBound, through: range.upperBound)
            let amounts = dates.map(recurring.scheduledAmount(paidOn:))
            return sum + amounts.reduce(0, +)
        }
    }

    func total(
        of type: Entry.Kind,
        in range: ClosedRange<LocalDate>,
        entries: [Entry]
    ) -> Int {
        let recorded = entries.filter { $0.recurringId != nil }

        return filter { $0.type == type }.reduce(0) { sum, recurring in
            let occurrences = recurring.occurrences(
                from: range.lowerBound,
                through: range.upperBound
            )

            let amounts = occurrences.map { occurrence in
                recurring.record(of: occurrence, in: recorded)?.amount
                    ?? recurring.amount(paidOn: occurrence.date, entries: entries)
            }

            return sum + amounts.reduce(0, +)
        }
    }
}
