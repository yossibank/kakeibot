import Foundation
import GRDB

protocol SortableRecord: StoreRecord, Identifiable
    where ID: DatabaseValueConvertible {
    var sortOrder: Int { get set }
    var updatedAt: Date { get set }
}

extension SortableRecord {
    static var sortOrder: Column {
        Column("sort_order")
    }

    static func reorder(
        _ ids: [ID],
        orThrow notFound: some Error,
        in db: Database,
        at now: Date
    ) throws {
        for (order, id) in ids.enumerated() {
            guard var record = try fetchOne(db, key: id) else {
                throw notFound
            }

            guard record.sortOrder != order else {
                continue
            }

            record.sortOrder = order
            record.updatedAt = now

            try record.update(db)
        }
    }

    static func nextSortOrder(in db: Database) throws -> Int {
        try nextSortOrder(of: all(), in: db)
    }

    static func nextSortOrder(
        of request: QueryInterfaceRequest<Self>,
        in db: Database
    ) throws -> Int {
        let maxOrder = try request
            .select(max(sortOrder), as: Int?.self)
            .fetchOne(db)

        return (maxOrder ?? nil).map { $0 + 1 } ?? 0
    }
}
