import GRDB

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
