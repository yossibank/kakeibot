import Foundation

public struct EntryItem: Codable, Hashable, Identifiable, Sendable {
    public let id: ID

    public var entryId: Entry.ID
    public var name: String
    public var quantity: Int
    public var amount: Int
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        entryId: Entry.ID,
        name: String,
        quantity: Int = 1,
        amount: Int,
        sortOrder: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.entryId = entryId
        self.name = name
        self.quantity = quantity
        self.amount = amount
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension EntryItem {
    typealias ID = Identifier<EntryItem>

    struct Draft: Hashable, Sendable {
        public var name: String
        public var quantity: Int
        public var amount: Int

        public init(
            name: String,
            quantity: Int = 1,
            amount: Int
        ) {
            self.name = name
            self.quantity = quantity
            self.amount = amount
        }

        public init(_ item: EntryItem) {
            self.init(name: item.name, quantity: item.quantity, amount: item.amount)
        }
    }
}

public extension EntryItem.Draft {
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
