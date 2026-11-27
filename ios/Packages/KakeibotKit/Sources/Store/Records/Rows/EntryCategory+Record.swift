import Core
import GRDB

extension EntryCategory: StoreRecord {
    public static let databaseTableName = "category"
}

extension EntryCategory.Kind: DatabaseValueConvertible {}

extension EntryCategory: ArchivableRecord {
    static var notFound: any Error {
        AppDatabase.CategoryWriteError.categoryNotFound
    }
}

extension EntryCategory: IconBackedRecord {
    static var iconNotFound: any Error {
        AppDatabase.CategoryWriteError.iconNotFound
    }
}

extension EntryCategory: ArchivableRow {
    public static let ordering = OrderedRowWrite<EntryCategory>.sortable
    public static let hiding = HidableRowWrite<EntryCategory>.hidable
}
