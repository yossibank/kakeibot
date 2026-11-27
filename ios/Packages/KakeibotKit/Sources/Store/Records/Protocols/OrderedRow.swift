import Core
import Foundation
import GRDB

public protocol OrderedRow: Identifiable, Sendable where ID == Identifier<Self> {
    static var ordering: OrderedRowWrite<Self> { get }
}

public struct OrderedRowWrite<Row: Identifiable>: Sendable {
    let reorder: @Sendable ([Row.ID], Database, Date) throws -> Void
}

extension OrderedRowWrite where Row: SortableRecord {
    static var sortable: Self {
        Self { ids, db, now in
            try Row.reorder(ids, in: db, at: now)
        }
    }
}
