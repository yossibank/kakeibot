import Foundation

public struct ReviewGoal: Hashable, Identifiable, Sendable {
    public let id: ID
    public let period: String

    public var kind: Kind
    public var categoryId: EntryCategory.ID?
    public var memo: String?
    public var baseline: Int
    public var target: Int
    public var saving: Int
    public var result: Int?
    public var saved: Int?
    public var createdAt: Date
    public var checkedAt: Date?

    public init(
        id: ID = ID(),
        period: String,
        kind: Kind,
        categoryId: EntryCategory.ID?,
        memo: String? = nil,
        baseline: Int,
        target: Int,
        saving: Int,
        result: Int? = nil,
        saved: Int? = nil,
        createdAt: Date,
        checkedAt: Date? = nil
    ) {
        self.id = id
        self.period = period
        self.kind = kind
        self.categoryId = categoryId
        self.memo = memo
        self.baseline = baseline
        self.target = target
        self.saving = saving
        self.result = result
        self.saved = saved
        self.createdAt = createdAt
        self.checkedAt = checkedAt
    }
}

public extension ReviewGoal {
    typealias ID = Identifier<ReviewGoal>

    enum Kind: String, Codable, Hashable, Sendable {
        case count
        case average
    }
}

public extension ReviewGoal {
    var isAchieved: Bool? {
        result.map { $0 <= target }
    }
}

extension ReviewGoal: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(period, forKey: .period)
        try container.encode(kind, forKey: .kind)
        try container.encodeOrNull(categoryId, forKey: .categoryId)
        try container.encodeOrNull(memo, forKey: .memo)
        try container.encode(baseline, forKey: .baseline)
        try container.encode(target, forKey: .target)
        try container.encode(saving, forKey: .saving)
        try container.encodeOrNull(result, forKey: .result)
        try container.encodeOrNull(saved, forKey: .saved)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeOrNull(checkedAt, forKey: .checkedAt)
    }
}
