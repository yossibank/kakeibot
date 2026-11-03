import Foundation
import GRDB
import Synchronization

public protocol StoreRecord: Codable, FetchableRecord, PersistableRecord {}

public extension StoreRecord {
    static var databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy {
        .custom(StoreColumnKey.init(column:))
    }

    static var databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy {
        .convertToSnakeCase
    }

    static func databaseDateDecodingStrategy(for column: String) -> DatabaseDateDecodingStrategy {
        .custom(Date.init(storedValue:))
    }

    static func databaseDateEncodingStrategy(for column: String) -> DatabaseDateEncodingStrategy {
        .iso8601
    }
}

private struct StoreColumnKey {
    let stringValue: String
}

private extension StoreColumnKey {
    static let keys = Mutex<[String: String]>([:])

    init(column: String) {
        if let key = Self.keys.withLock({ $0[column] }) {
            self.init(stringValue: key)
            return
        }

        let key = Self.camelCase(column)

        Self.keys.withLock { keys in
            keys[column] = key
        }

        self.init(stringValue: key)
    }

    static func camelCase(_ column: String) -> String {
        let words = column.split(separator: "_")

        guard let first = words.first else {
            return column
        }

        return words.dropFirst().reduce(first.lowercased()) { $0 + $1.capitalized }
    }
}

extension StoreColumnKey: CodingKey {
    var intValue: Int? {
        nil
    }

    init?(intValue: Int) {
        nil
    }
}

extension Date {
    static let fractionalStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    init?(storedValue: DatabaseValue) {
        guard
            let text = String.fromDatabaseValue(storedValue),
            let date = Self.stored(text)
        else {
            return nil
        }

        self = date
    }

    static func stored(_ text: String) -> Date? {
        (try? Date(text, strategy: .iso8601)) ?? (try? Date(text, strategy: fractionalStyle))
    }
}
