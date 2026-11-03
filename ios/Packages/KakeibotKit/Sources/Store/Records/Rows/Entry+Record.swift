import Core
import GRDB

extension Entry: StoreRecord {
    public static let databaseTableName = "entry"
}

extension Entry.Kind: DatabaseValueConvertible {}
