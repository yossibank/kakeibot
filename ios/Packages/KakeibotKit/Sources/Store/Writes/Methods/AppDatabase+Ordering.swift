import Core
import Foundation

public extension AppDatabase {
    func reorder<Record: SortableRecord>(
        _ ids: [Identifier<Record>],
        at now: Date
    ) async throws where Record.ID == Identifier<Record> {
        try await writer.write { db in
            try Record.reorder(ids, in: db, at: now)
        }
    }

    func setHidden<Record: HidableRecord>(
        _ id: Identifier<Record>,
        isHidden: Bool,
        at now: Date
    ) async throws where Record.ID == Identifier<Record> {
        try await writer.write { db in
            try Record.setHidden(id, isHidden, in: db, at: now)
        }
    }
}
