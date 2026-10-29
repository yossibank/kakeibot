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

public struct SyncRecordID: Hashable, Sendable {
    public let key: SyncKey
    public let zoneName: String

    public init(
        key: SyncKey,
        zoneName: String
    ) {
        self.key = key
        self.zoneName = zoneName
    }
}

public struct SyncChange: Hashable, Sendable {
    public let key: SyncKey
    public let isDeletion: Bool
    public let saveZone: String?
    public let deleteZones: [String]

    let version: Int64
}

public struct SyncActivity: Hashable, Sendable {
    public let isSyncEnabled: Bool
    public let isSharing: Bool

    public init(
        isSyncEnabled: Bool,
        isSharing: Bool
    ) {
        self.isSyncEnabled = isSyncEnabled
        self.isSharing = isSharing
    }
}

public extension SyncActivity {
    var isActive: Bool {
        isSyncEnabled || isSharing
    }
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
