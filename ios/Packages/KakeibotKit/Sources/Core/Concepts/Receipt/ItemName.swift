import Foundation

public struct ItemName: Codable, Hashable, Identifiable, Sendable {
    public let id: ID

    public var store: String
    public var raw: String
    public var name: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        store: String,
        raw: String,
        name: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.store = store
        self.raw = raw
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension ItemName {
    typealias ID = Identifier<ItemName>
}
