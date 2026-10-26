import Foundation

public struct Wallet: Hashable, Sendable {
    public let id: ID

    public var name: String
    public var kind: Kind
    public var iconId: Icon.ID
    public var initialBalance: Int
    public var loanAmount: Int?
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
        loanAmount: Int? = nil,
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
        self.loanAmount = loanAmount
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
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case kind
        case iconId
        case initialBalance
        case loanAmount
        case sortOrder
        case archivedAt
        case createdAt
        case updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(
            id: container.decode(ID.self, forKey: .id),
            name: container.decode(String.self, forKey: .name),
            kind: container.decode(Kind.self, forKey: .kind),
            iconId: container.decode(Icon.ID.self, forKey: .iconId),
            initialBalance: container.decode(Int.self, forKey: .initialBalance),
            loanAmount: container.decodeIfPresent(
                Int.self,
                forKey: .loanAmount
            ),
            sortOrder: container.decode(Int.self, forKey: .sortOrder),
            archivedAt: container.decodeIfPresent(
                Date.self,
                forKey: .archivedAt
            ),
            createdAt: container.decode(Date.self, forKey: .createdAt),
            updatedAt: container.decode(Date.self, forKey: .updatedAt)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(kind, forKey: .kind)
        try container.encode(iconId, forKey: .iconId)
        try container.encode(initialBalance, forKey: .initialBalance)
        try container.encodeOrNull(loanAmount, forKey: .loanAmount)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encodeOrNull(archivedAt, forKey: .archivedAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
