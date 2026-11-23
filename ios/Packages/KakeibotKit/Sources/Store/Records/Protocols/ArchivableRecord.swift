import Foundation
import GRDB

protocol ArchivableRecord: SortableRecord {
    var archivedAt: Date? { get set }
}

extension ArchivableRecord {
    static func unarchivedInOrder() -> QueryInterfaceRequest<Self> {
        filter(archivedAt == nil).order(sortOrder)
    }

    static func setHidden(
        _ id: ID,
        _ isHidden: Bool,
        orThrow notFound: some Error,
        in db: Database,
        at now: Date
    ) throws {
        guard var record = try fetchOne(db, key: id) else {
            throw notFound
        }

        record.archivedAt = isHidden ? now : nil
        record.updatedAt = now

        try record.update(db)
    }
}

private extension ArchivableRecord {
    static var archivedAt: Column {
        Column("archived_at")
    }
}
