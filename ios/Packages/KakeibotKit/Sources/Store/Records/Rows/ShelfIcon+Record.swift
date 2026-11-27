import Core
import GRDB

extension ShelfIcon: StoreRecord {
    public static let databaseTableName = "shelf_icon"
}

extension ShelfIcon: ArchivableRecord {
    public static var notFound: any Error {
        AppDatabase.ShelfIconWriteError.shelfIconNotFound
    }
}

extension ShelfIcon: IconBackedRecord {
    public static var iconNotFound: any Error {
        AppDatabase.ShelfIconWriteError.iconNotFound
    }
}

extension ShelfIcon: ArchivableRow {
    public static let ordering = OrderedRowWrite<ShelfIcon>.sortable
    public static let hiding = HidableRowWrite<ShelfIcon>.hidable
}
