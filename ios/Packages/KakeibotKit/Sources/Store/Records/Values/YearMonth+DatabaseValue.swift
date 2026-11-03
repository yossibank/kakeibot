import Core
import GRDB

extension YearMonth: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        description.databaseValue
    }

    public static func fromDatabaseValue(
        _ dbValue: DatabaseValue
    ) -> YearMonth? {
        String.fromDatabaseValue(dbValue).flatMap(YearMonth.init)
    }
}
