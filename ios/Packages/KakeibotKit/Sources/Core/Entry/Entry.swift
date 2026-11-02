import Foundation

public struct Entry: Hashable, Identifiable, Sendable {
    public let id: ID

    public var type: Kind
    public var amount: Int
    public var date: LocalDate
    public var categoryId: EntryCategory.ID?
    public var tagId: EntryTag.ID?
    public var templateId: EntryTemplate.ID?
    public var walletId: Wallet.ID
    public var toWalletId: Wallet.ID?
    public var memo: String?
    public var recurringId: Recurring.ID?
    public var recurringDate: LocalDate?
    public var billMonth: YearMonth?
    public var transferId: Entry.ID?
    public var taxIncluded: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        type: Kind,
        amount: Int,
        date: LocalDate,
        categoryId: EntryCategory.ID?,
        tagId: EntryTag.ID? = nil,
        templateId: EntryTemplate.ID? = nil,
        walletId: Wallet.ID,
        toWalletId: Wallet.ID? = nil,
        memo: String? = nil,
        recurringId: Recurring.ID? = nil,
        recurringDate: LocalDate? = nil,
        billMonth: YearMonth? = nil,
        transferId: Entry.ID? = nil,
        taxIncluded: Bool = false,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.date = date
        self.categoryId = categoryId
        self.tagId = tagId
        self.templateId = templateId
        self.walletId = walletId
        self.toWalletId = toWalletId
        self.memo = memo
        self.recurringId = recurringId
        self.recurringDate = recurringDate
        self.billMonth = billMonth
        self.transferId = transferId
        self.taxIncluded = taxIncluded
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

extension Entry: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case amount
        case date
        case categoryId
        case tagId
        case templateId
        case walletId
        case toWalletId
        case memo
        case recurringId
        case recurringDate
        case billMonth
        case transferId
        case taxIncluded
        case createdAt
        case updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(ID.self, forKey: .id)
        self.type = try container.decode(Kind.self, forKey: .type)
        self.amount = try container.decode(Int.self, forKey: .amount)
        self.date = try container.decode(LocalDate.self, forKey: .date)
        self.categoryId = try container.decodeIfPresent(EntryCategory.ID.self, forKey: .categoryId)
        self.tagId = try container.decodeIfPresent(EntryTag.ID.self, forKey: .tagId)
        self.templateId = try container.decodeIfPresent(EntryTemplate.ID.self, forKey: .templateId)
        self.walletId = try container.decode(Wallet.ID.self, forKey: .walletId)
        self.toWalletId = try container.decodeIfPresent(Wallet.ID.self, forKey: .toWalletId)
        self.memo = try container.decodeIfPresent(String.self, forKey: .memo)
        self.recurringId = try container.decodeIfPresent(Recurring.ID.self, forKey: .recurringId)
        self.recurringDate = try container.decodeIfPresent(LocalDate.self, forKey: .recurringDate)
        self.billMonth = try container.decodeIfPresent(YearMonth.self, forKey: .billMonth)
        self.transferId = try container.decodeIfPresent(Entry.ID.self, forKey: .transferId)
        self.taxIncluded = try container.decodeIfPresent(Bool.self, forKey: .taxIncluded) ?? false
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(amount, forKey: .amount)
        try container.encode(date, forKey: .date)
        try container.encodeOrNull(categoryId, forKey: .categoryId)
        try container.encodeOrNull(tagId, forKey: .tagId)
        try container.encodeOrNull(templateId, forKey: .templateId)
        try container.encode(walletId, forKey: .walletId)
        try container.encodeOrNull(toWalletId, forKey: .toWalletId)
        try container.encodeOrNull(memo, forKey: .memo)
        try container.encodeOrNull(recurringId, forKey: .recurringId)
        try container.encodeOrNull(recurringDate, forKey: .recurringDate)
        try container.encodeOrNull(billMonth, forKey: .billMonth)
        try container.encodeOrNull(transferId, forKey: .transferId)
        try container.encode(taxIncluded, forKey: .taxIncluded)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
