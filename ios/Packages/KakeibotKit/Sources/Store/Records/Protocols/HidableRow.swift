import Foundation
import GRDB

public protocol HidableRow: OrderedRow {
    static var hiding: HidableRowWrite<Self> { get }
}

public struct HidableRowWrite<Row: Identifiable>: Sendable {
    let setHidden: @Sendable (Row.ID, Bool, Database, Date) throws -> Void
}

extension HidableRowWrite where Row: HidableRecord {
    static var hidable: Self {
        Self { id, isHidden, db, now in
            try Row.setHidden(id, isHidden, in: db, at: now)
        }
    }
}
