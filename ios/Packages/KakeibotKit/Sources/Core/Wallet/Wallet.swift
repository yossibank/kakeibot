import Foundation

public struct Wallet: Hashable, Sendable {
    public let id: ID

    public var name: String
    public var kind: Kind
    public var iconId: Icon.ID
    public var initialBalance: Int
    public var sortOrder: Int
    public var archivedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        name: String,
        kind: Kind,
        iconId: Icon.ID,
        initialBalance: Int,
        sortOrder: Int,
        archivedAt: Date? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.iconId = iconId
        self.initialBalance = initialBalance
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Wallet {
    typealias ID = Identifier<Wallet>

    enum Kind: String, CaseIterable, Codable, Sendable {
        case cash
        case bank
        case card
        case emoney
        case point
        case other
        case investment
        case loan
    }
}

extension Wallet: Identifiable {}

extension Wallet: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(kind, forKey: .kind)
        try container.encode(iconId, forKey: .iconId)
        try container.encode(initialBalance, forKey: .initialBalance)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encodeOrNull(archivedAt, forKey: .archivedAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
