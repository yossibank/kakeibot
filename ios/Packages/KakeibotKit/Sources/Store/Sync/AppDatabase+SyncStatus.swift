import Foundation
import GRDB

public extension AppDatabase {
    func syncStatus() async throws -> SyncStatus {
        try await writer.read { db in
            try Self.syncStatus(in: db)
        }
    }

    func syncStatusUpdates() -> some AsyncSequence<SyncStatus, any Error> {
        ValueObservation
            .tracking { db in
                try Self.syncStatus(in: db)
            }
            .removeDuplicates()
            .values(in: writer)
    }
}

private extension AppDatabase {
    static func syncStatus(in db: Database) throws -> SyncStatus {
        let row = try Row.fetchOne(db, sql: "SELECT enabled, stop_reason FROM sync_state")
        let reason: String? = row?["stop_reason"]

        return SyncStatus(
            isEnabled: row?["enabled"] ?? false,
            stopReason: reason.flatMap(SyncStopReason.init)
        )
    }
}
