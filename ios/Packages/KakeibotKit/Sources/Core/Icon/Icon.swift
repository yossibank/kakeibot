import Foundation

public struct Icon: Hashable, Sendable {
    public let id: ID
    public var emoji: String?
    public var text: String?
    public var color: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        emoji: String?,
        text: String?,
        color: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.emoji = emoji
        self.text = text
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Icon {
    typealias ID = Identifier<Icon>
}

extension Icon: Identifiable {}

extension Icon: Codable {}
