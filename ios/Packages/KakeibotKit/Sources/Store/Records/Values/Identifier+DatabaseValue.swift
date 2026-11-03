import Core
import GRDB

extension Identifier: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        description.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Identifier? {
        String.fromDatabaseValue(dbValue).flatMap { Identifier($0) }
    }
}
