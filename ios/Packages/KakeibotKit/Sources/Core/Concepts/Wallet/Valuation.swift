import Foundation

public struct Valuation: Codable, Hashable, Identifiable, Sendable {
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

    func includes(_ entry: Entry) -> Bool {
        includes(date: entry.date, createdAt: entry.createdAt)
    }

    func includes(_ adjustment: Adjustment) -> Bool {
        includes(date: adjustment.date, createdAt: adjustment.createdAt)
    }
}

private extension Valuation {
    func includes(
        date: LocalDate,
        createdAt: Date
    ) -> Bool {
        if date == self.date {
            return createdAt <= self.createdAt
        }

        return date < self.date
    }
}
