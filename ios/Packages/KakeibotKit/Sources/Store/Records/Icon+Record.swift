import Core
import GRDB

extension Icon: StoreRecord {
    public static let databaseTableName = "icon"
}

extension Icon.Glyph: DatabaseValueConvertible {}
