import Core
import GRDB

extension EntryTemplate: StoreRecord {
    public static let databaseTableName = "template"
}

extension EntryTemplate: SortableRecord {}
