import Foundation

public struct Entry: Hashable, Sendable {
    public let id: ID
    public var type: Kind
    public var amount: Int
    public var date: LocalDate
    public var categoryId: EntryCategory.ID?
    public var tagId: EntryTag.ID?
    public var walletId: Wallet.ID
    public var toWalletId: Wallet.ID?
    public var memo: String?
    public var recurringId: Recurring.ID?
    public var recurringDate: LocalDate?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        type: Kind,
        amount: Int,
        date: LocalDate,
        categoryId: EntryCategory.ID?,
        tagId: EntryTag.ID? = nil,
        walletId: Wallet.ID,
        toWalletId: Wallet.ID? = nil,
        memo: String? = nil,
        recurringId: Recurring.ID? = nil,
        recurringDate: LocalDate? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.date = date
        self.categoryId = categoryId
        self.tagId = tagId
        self.walletId = walletId
        self.toWalletId = toWalletId
        self.memo = memo
        self.recurringId = recurringId
        self.recurringDate = recurringDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Entry {
    typealias ID = Identifier<Entry>

    enum Kind: String, CaseIterable, Codable, Sendable {
        case expense
        case income
        case transfer
    }
}

extension Entry: Identifiable {}

extension Entry: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(amount, forKey: .amount)
        try container.encode(date, forKey: .date)
        try container.encodeOrNull(categoryId, forKey: .categoryId)
        try container.encodeOrNull(tagId, forKey: .tagId)
        try container.encode(walletId, forKey: .walletId)
        try container.encodeOrNull(toWalletId, forKey: .toWalletId)
        try container.encodeOrNull(memo, forKey: .memo)
        try container.encodeOrNull(recurringId, forKey: .recurringId)
        try container.encodeOrNull(recurringDate, forKey: .recurringDate)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
