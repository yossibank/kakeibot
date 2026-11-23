import Core
import GRDB

extension ShelfIcon: StoreRecord {
    public static let databaseTableName = "shelf_icon"
}

extension ShelfIcon: ArchivableRecord, IconBackedRecord {
    public static var notFound: any Error {
        AppDatabase.ShelfIconWriteError.shelfIconNotFound
    }

    public static var iconNotFound: any Error {
        AppDatabase.ShelfIconWriteError.iconNotFound
    }
}
