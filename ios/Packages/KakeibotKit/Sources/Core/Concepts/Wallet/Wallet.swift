import Foundation

public struct Wallet: Hashable, Identifiable, Sendable {
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
        let id = try container.decode(ID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let kind = try container.decode(Kind.self, forKey: .kind)
        let iconId = try container.decode(Icon.ID.self, forKey: .iconId)
        let initialBalance = try container.decode(Int.self, forKey: .initialBalance)
        let loanAmount = try container.decodeIfPresent(Int.self, forKey: .loanAmount)
        let sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        let archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        self.init(
            id: id,
            name: name,
            kind: kind,
            iconId: iconId,
            initialBalance: initialBalance,
            loanAmount: loanAmount,
            sortOrder: sortOrder,
            archivedAt: archivedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
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
