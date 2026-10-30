import Foundation
import GRDB

public extension AppDatabase {
    func syncSummary() async throws -> SyncSummary {
        try await writer.read { db in
            let row = try Row.fetchOne(
                db,
                sql: """
                SELECT COUNT(*) AS count, MAX(updated_at) AS latest FROM entry
                WHERE wallet_id NOT IN (SELECT wallet_id FROM sync_share)
                """
            )

            return SyncSummary(
                entryCount: row?["count"] ?? 0,
                latestUpdate: row?["latest"]
            )
        }
    }
}

public extension SyncSummary {
    init(
        entryCount: Int,
        latestUpdate: String?
    ) {
        self.init(
            entryCount: entryCount,
            updatedAt: latestUpdate.flatMap(Date.stored)
        )
    }
}
