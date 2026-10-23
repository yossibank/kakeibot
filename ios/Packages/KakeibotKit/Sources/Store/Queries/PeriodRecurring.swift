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
