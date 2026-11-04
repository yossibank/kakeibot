import Foundation

public struct EntryTemplate: Hashable, Identifiable, Sendable {
    public let id: ID

    public var name: String
    public var type: Entry.Kind
    public var amount: Int?
    public var categoryId: EntryCategory.ID
    public var tagId: EntryTag.ID?
    public var walletId: Wallet.ID
    public var memo: String?
    public var billShift: Int
    public var sortOrder: Int
    public var archivedAt: Date?
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
        billShift: Int = 0,
        sortOrder: Int,
        archivedAt: Date? = nil,
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
        self.billShift = billShift
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
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

extension EntryTemplate: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case amount
        case categoryId
        case tagId
        case walletId
        case memo
        case billShift
        case sortOrder
        case archivedAt
        case createdAt
        case updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(ID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let type = try container.decode(Entry.Kind.self, forKey: .type)
        let amount = try container.decodeIfPresent(Int.self, forKey: .amount)
        let categoryId = try container.decode(EntryCategory.ID.self, forKey: .categoryId)
        let tagId = try container.decodeIfPresent(EntryTag.ID.self, forKey: .tagId)
        let walletId = try container.decode(Wallet.ID.self, forKey: .walletId)
        let memo = try container.decodeIfPresent(String.self, forKey: .memo)
        let billShift = try container.decodeIfPresent(Int.self, forKey: .billShift)
        let sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        let archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        let clampedShift = Recurring.clampedBillShift(billShift ?? 0)

        self.init(
            id: id,
            name: name,
            type: type,
            amount: amount,
            categoryId: categoryId,
            tagId: tagId,
            walletId: walletId,
            memo: memo,
            billShift: clampedShift,
            sortOrder: sortOrder,
            archivedAt: archivedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

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
        try container.encode(billShift, forKey: .billShift)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encodeOrNull(archivedAt, forKey: .archivedAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
