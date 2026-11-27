import Core
import Foundation

public extension AppDatabase {
    func reorder<Row: OrderedRow>(
        _ ids: [Identifier<Row>],
        at now: Date
    ) async throws {
        try await writer.write { db in
            try Row.ordering.reorder(ids, db, now)
        }
    }

    func setHidden<Row: HidableRow>(
        _ id: Identifier<Row>,
        isHidden: Bool,
        at now: Date
    ) async throws {
        try await writer.write { db in
            try Row.hiding.setHidden(id, isHidden, db, now)
        }
    }
}
