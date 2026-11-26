import Core
import GRDB

extension Icon {
    static func byID(
        _ ids: [ID],
        in db: Database
    ) throws -> [ID: Icon] {
        let pairs = try fetchAll(db, keys: ids).map { ($0.id, $0) }
        return Dictionary(uniqueKeysWithValues: pairs)
    }
}

extension Icon: StoreRecord {
    public static let databaseTableName = "icon"
}

extension Icon.Glyph: DatabaseValueConvertible {
    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
        String.fromDatabaseValue(dbValue).map(Self.init(known:))
    }
}
