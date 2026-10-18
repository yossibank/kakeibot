public extension [Recurring] {
    func total(
        of type: Entry.Kind,
        in range: ClosedRange<LocalDate>
    ) -> Int {
        filter { $0.type == type }.reduce(0) { sum, recurring in
            let dates = recurring.dates(
                from: range.lowerBound,
                through: range.upperBound
            )

            return sum + recurring.amount * dates.count
        }
    }
}
