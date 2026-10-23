import Foundation

public struct RewardRule: Hashable, Sendable {
    public let id: ID

    public var name: String
    public var amount: Int
    public var iconId: Icon.ID
    public var isActive: Bool
    public var sortOrder: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        name: String,
        amount: Int,
        iconId: Icon.ID,
        isActive: Bool,
        sortOrder: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.iconId = iconId
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension RewardRule {
    typealias ID = Identifier<RewardRule>
}

extension RewardRule: Identifiable {}

extension RewardRule: Codable {}
