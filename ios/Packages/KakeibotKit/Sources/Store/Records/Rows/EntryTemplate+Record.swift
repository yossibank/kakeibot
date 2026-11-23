import Core
import GRDB

extension EntryTemplate: StoreRecord {
    public static let databaseTableName = "template"
}

extension EntryTemplate: ArchivableRecord {
    public static var notFound: any Error {
        AppDatabase.TemplateWriteError.templateNotFound
    }
}
