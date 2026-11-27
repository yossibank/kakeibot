import Core
import GRDB

extension EntryTemplate: StoreRecord {
    public static let databaseTableName = "template"
}

extension EntryTemplate: ArchivableRecord {
    static var notFound: any Error {
        AppDatabase.TemplateWriteError.templateNotFound
    }
}

extension EntryTemplate: ArchivableRow {
    public static let ordering = OrderedRowWrite<EntryTemplate>.sortable
    public static let hiding = HidableRowWrite<EntryTemplate>.hidable
}
