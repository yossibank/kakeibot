import Foundation

public struct EntryTemplate: Hashable, Sendable {
    public let id: ID
    public var name: String
    public var type: Entry.Kind
    public var amount: Int?
    public var categoryId: EntryCategory.ID
    public var tagId: EntryTag.ID?
    public var walletId: Wallet.ID
    public var memo: String?
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        name: String,
        type: Entry.Kind,
        amount: Int?,
        categoryId: EntryCategory.ID,
        tagId: EntryTag.ID? = nil,
        walletId: Wallet.ID,
        memo: String? = nil,
        sortOrder: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.amount = amount
        self.categoryId = categoryId
        self.tagId = tagId
        self.walletId = walletId
        self.memo = memo
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension EntryTemplate {
    typealias ID = Identifier<EntryTemplate>

    func entryDraft(on date: LocalDate) -> EntryDraft? {
        guard let amount else {
            return nil
        }

        return EntryDraft(
            type: type,
            amount: amount,
            date: date,
            categoryId: categoryId,
            tagId: tagId,
            templateId: id,
            walletId: walletId,
            memo: memo ?? ""
        )
    }
}

extension EntryTemplate: Identifiable {}

extension EntryTemplate: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encodeOrNull(amount, forKey: .amount)
        try container.encode(categoryId, forKey: .categoryId)
        try container.encodeOrNull(tagId, forKey: .tagId)
        try container.encode(walletId, forKey: .walletId)
        try container.encodeOrNull(memo, forKey: .memo)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
