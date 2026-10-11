import Core
import GRDB

extension EntryCategory: StoreRecord {
    public static let databaseTableName = "category"
}

extension EntryCategory.Kind: DatabaseValueConvertible {}
