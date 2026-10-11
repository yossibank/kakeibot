import Foundation

public struct EntryCategory: Hashable, Sendable {
    public let id: ID
    public var kind: Kind
    public var name: String
    public var iconId: Icon.ID
    public var sortOrder: Int
    public var archivedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        kind: Kind,
        name: String,
        iconId: Icon.ID,
        sortOrder: Int,
        archivedAt: Date? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.iconId = iconId
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension EntryCategory {
    typealias ID = Identifier<EntryCategory>

    enum Kind: String, CaseIterable, Codable, Sendable {
        case expense
        case income
    }
}

extension EntryCategory: Identifiable {}

extension EntryCategory: Codable {}
