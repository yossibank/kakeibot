import Foundation

public struct RewardGoal: Hashable, Sendable {
    public let id: ID
    public var name: String
    public var targetAmount: Int
    public var purchasedAt: Date?
    public var entryId: Entry.ID?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        name: String,
        targetAmount: Int,
        purchasedAt: Date? = nil,
        entryId: Entry.ID? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.purchasedAt = purchasedAt
        self.entryId = entryId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension RewardGoal {
    typealias ID = Identifier<RewardGoal>
}

extension RewardGoal: Identifiable {}

extension RewardGoal: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(targetAmount, forKey: .targetAmount)
        try container.encodeOrNull(purchasedAt, forKey: .purchasedAt)
        try container.encodeOrNull(entryId, forKey: .entryId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
