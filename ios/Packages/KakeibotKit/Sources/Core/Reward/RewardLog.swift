import Foundation

public struct RewardLog: Hashable, Sendable {
    public let id: ID

    public var ruleId: RewardRule.ID
    public var date: LocalDate
    public var amount: Int
    public var createdAt: Date

    public init(
        id: ID = ID(),
        ruleId: RewardRule.ID,
        date: LocalDate,
        amount: Int,
        createdAt: Date
    ) {
        self.id = id
        self.ruleId = ruleId
        self.date = date
        self.amount = amount
        self.createdAt = createdAt
    }
}

public extension RewardLog {
    typealias ID = Identifier<RewardLog>
}

extension RewardLog: Identifiable {}

extension RewardLog: Codable {}
