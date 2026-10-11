import Foundation

public struct Entry: Hashable, Sendable {
    public let id: ID
    public var type: Kind
    public var amount: Int
    public var date: LocalDate
    public var categoryId: EntryCategory.ID?
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

extension Entry: Codable {}
