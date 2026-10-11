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

extension Budget: Identifiable {}

extension Budget: Codable {}
