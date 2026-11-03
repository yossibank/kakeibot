import Core
import GRDB

extension ShelfIcon: StoreRecord {
    public static let databaseTableName = "shelf_icon"
}

extension ShelfIcon: ArchivableRecord {}
