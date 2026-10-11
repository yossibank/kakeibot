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

extension Icon: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeOrNull(emoji, forKey: .emoji)
        try container.encodeOrNull(text, forKey: .text)
        try container.encode(color, forKey: .color)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
