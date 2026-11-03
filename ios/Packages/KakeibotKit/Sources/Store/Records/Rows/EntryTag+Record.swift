import Core
import GRDB

extension EntryTag: StoreRecord {
    public static let databaseTableName = "tag"
}

extension EntryTag: ArchivableRecord {}
