import Foundation

public struct Valuation: Hashable, Sendable {
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

public extension Valuation {
    typealias ID = Identifier<Valuation>
}

extension Valuation: Identifiable {}

extension Valuation: Codable {}
