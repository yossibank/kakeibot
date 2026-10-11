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
    }
}

extension Wallet: Identifiable {}

extension Wallet: Codable {}
