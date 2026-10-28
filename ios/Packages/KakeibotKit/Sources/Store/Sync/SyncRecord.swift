import GRDB

public struct SyncRecord: Hashable, Sendable {
    public let key: SyncKey
    public let values: [String: SyncValue]

    public init(
        key: SyncKey,
        values: [String: SyncValue]
    ) {
        self.key = key
        self.values = values
    }
}

public struct SyncKey: Hashable, Sendable {
    public let table: SyncTable
    public let id: String

    public init(
        table: SyncTable,
        id: String
    ) {
        self.table = table
        self.id = id
    }
}

public struct SyncChange: Hashable, Sendable {
    public let key: SyncKey
    public let isDeletion: Bool

    let version: Int64
}

public enum SyncValue: Codable, Hashable, Sendable {
    case null
    case integer(Int64)
    case text(String)

    var databaseValue: DatabaseValue {
        switch self {
        case .null: .null
        case let .integer(number): number.databaseValue
        case let .text(text): text.databaseValue
        }
    }

    init(_ value: DatabaseValue) {
        switch value.storage {
        case let .int64(number): self = .integer(number)
        case let .double(number): self = .integer(Int64(number))
        case let .string(text): self = .text(text)
        case .null, .blob: self = .null
        }
    }
}
