import Foundation
import GRDB

protocol ArchivableRecord: HidableRecord {
    var archivedAt: Date? { get set }
}

extension ArchivableRecord {
    static func setHidden(
        _ id: ID,
        _ isHidden: Bool,
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

    static func unarchivedInOrder() -> QueryInterfaceRequest<Self> {
        filter(archivedAt == nil).order(sortOrder)
    }
}

private extension ArchivableRecord {
    static var archivedAt: Column {
        Column("archived_at")
    }
}
