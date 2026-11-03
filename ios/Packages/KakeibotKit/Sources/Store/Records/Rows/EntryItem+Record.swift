import Core
import GRDB

extension EntryItem: StoreRecord {
    public static let databaseTableName = "entry_item"
}

extension EntryItem.TaxRate: DatabaseValueConvertible {}
