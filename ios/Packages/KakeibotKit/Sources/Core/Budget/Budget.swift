public struct Budget: Hashable, Sendable {
    public let id: ID
    public var categoryId: EntryCategory.ID?
    public var fromMonth: YearMonth
    public var amount: Int?

    public init(
        id: ID = ID(),
        categoryId: EntryCategory.ID?,
        fromMonth: YearMonth,
        amount: Int?
    ) {
        self.id = id
        self.categoryId = categoryId
        self.fromMonth = fromMonth
        self.amount = amount
    }
}

public extension Budget {
    typealias ID = Identifier<Budget>
}

public extension [Budget] {
    func amount(
        for categoryId: EntryCategory.ID?,
        in month: YearMonth
    ) -> Int? {
        let rows = filter { budget in
            budget.categoryId == categoryId && budget.fromMonth <= month
        }

        return rows.max { $0.fromMonth < $1.fromMonth }?.amount
    }
}

extension Budget: Identifiable {}

extension Budget: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeOrNull(categoryId, forKey: .categoryId)
        try container.encode(fromMonth, forKey: .fromMonth)
        try container.encodeOrNull(amount, forKey: .amount)
    }
}
