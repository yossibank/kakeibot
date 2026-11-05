import Foundation

public struct Adjustment: Codable, Hashable, Identifiable, Sendable {
    public let id: ID

    public var walletId: Wallet.ID
    public var date: LocalDate
    public var amount: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        walletId: Wallet.ID,
        date: LocalDate,
        amount: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.walletId = walletId
        self.date = date
        self.amount = amount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Adjustment {
    typealias ID = Identifier<Adjustment>
}
