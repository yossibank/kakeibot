import Foundation

public struct Recurring: Hashable, Sendable {
    public let id: ID
    public var type: Entry.Kind
    public var amount: Int
    public var categoryId: EntryCategory.ID?
    public var walletId: Wallet.ID
    public var toWalletId: Wallet.ID?
    public var memo: String?
    public var frequency: Frequency
    public var month: Int?
    public var day: Int
    public var startDate: LocalDate
    public var endDate: LocalDate?
    public var remindDaysBefore: Int?
    public var generatedUntil: LocalDate?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        type: Entry.Kind,
        amount: Int,
        categoryId: EntryCategory.ID?,
        walletId: Wallet.ID,
        toWalletId: Wallet.ID? = nil,
        memo: String? = nil,
        frequency: Frequency,
        month: Int? = nil,
        day: Int,
        startDate: LocalDate,
        endDate: LocalDate? = nil,
        remindDaysBefore: Int? = nil,
        generatedUntil: LocalDate? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.categoryId = categoryId
        self.walletId = walletId
        self.toWalletId = toWalletId
        self.memo = memo
        self.frequency = frequency
        self.month = month
        self.day = day
        self.startDate = startDate
        self.endDate = endDate
        self.remindDaysBefore = remindDaysBefore
        self.generatedUntil = generatedUntil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Recurring {
    typealias ID = Identifier<Recurring>

    enum Frequency: String, CaseIterable, Codable, Sendable {
        case monthly
        case yearly
    }
}

extension Recurring: Identifiable {}

extension Recurring: Codable {}
