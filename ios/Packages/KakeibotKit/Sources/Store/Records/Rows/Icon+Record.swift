import Core
import GRDB

extension Icon: StoreRecord {
    public static let databaseTableName = "icon"
}

extension Icon.Glyph: DatabaseValueConvertible {
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
        String.fromDatabaseValue(dbValue).map(Self.init(known:))
    }
}
