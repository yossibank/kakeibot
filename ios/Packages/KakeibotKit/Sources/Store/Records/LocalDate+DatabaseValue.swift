import Core
import GRDB

extension LocalDate: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        description.databaseValue
    }

    public static func fromDatabaseValue(
        _ dbValue: DatabaseValue
    ) -> LocalDate? {
        String.fromDatabaseValue(dbValue).flatMap(LocalDate.init)
    }
}
