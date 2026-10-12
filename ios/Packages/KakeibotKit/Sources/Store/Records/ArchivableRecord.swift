import GRDB

protocol ArchivableRecord: StoreRecord {}

extension ArchivableRecord {
    static func unarchivedInOrder() -> QueryInterfaceRequest<Self> {
        filter(archivedAt == nil).order(sortOrder)
    }
}

private extension ArchivableRecord {
    static var archivedAt: Column {
        Column("archived_at")
    }

    static var sortOrder: Column {
        Column("sort_order")
    }
}
