import Foundation

public struct EntryItem: Hashable, Identifiable, Sendable {
    public let id: ID

    public var entryId: Entry.ID
    public var name: String
    public var quantity: Int
    public var amount: Int
    public var taxRate: TaxRate?
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        entryId: Entry.ID,
        name: String,
        quantity: Int = 1,
        amount: Int,
        taxRate: TaxRate? = nil,
        sortOrder: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.entryId = entryId
        self.name = name
        self.quantity = quantity
        self.amount = amount
        self.taxRate = taxRate
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension EntryItem {
    typealias ID = Identifier<EntryItem>
    typealias TaxRate = AmountCalculator.TaxRate

    struct Draft: Hashable, Sendable {
        public var name: String
        public var quantity: Int
        public var amount: Int
        public var taxRate: TaxRate?

        public init(
            name: String,
            quantity: Int = 1,
            amount: Int,
            taxRate: TaxRate? = nil
        ) {
            self.name = name
            self.quantity = quantity
            self.amount = amount
            self.taxRate = taxRate
        }

        public init(_ item: EntryItem) {
            self.init(
                name: item.name,
                quantity: item.quantity,
                amount: item.amount,
                taxRate: item.taxRate
            )
        }
    }
}

public extension EntryItem.Draft {
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension EntryItem: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(entryId, forKey: .entryId)
        try container.encode(name, forKey: .name)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(amount, forKey: .amount)
        try container.encodeOrNull(taxRate, forKey: .taxRate)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
