import Core
import GRDB

extension EntryTag: StoreRecord {
    public static let databaseTableName = "tag"
}

extension EntryTag: ArchivableRecord {
    public static var notFound: any Error {
        AppDatabase.CategoryWriteError.tagNotFound
    }
}

extension EntryTag: ArchivableRow {
    public static let ordering = OrderedRowWrite<EntryTag>.sortable
    public static let hiding = HidableRowWrite<EntryTag>.hidable
}
