import Core
import GRDB

extension EntryCategory: StoreRecord {
    public static let databaseTableName = "category"
}

extension EntryCategory.Kind: DatabaseValueConvertible {}

extension EntryCategory: ArchivableRecord {
    public static var notFound: any Error {
        AppDatabase.CategoryWriteError.categoryNotFound
    }
}

extension EntryCategory: IconBackedRecord {
    public static var iconNotFound: any Error {
        AppDatabase.CategoryWriteError.iconNotFound
    }
}
