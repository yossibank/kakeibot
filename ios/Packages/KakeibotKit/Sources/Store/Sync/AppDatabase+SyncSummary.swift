import Foundation
import GRDB

public extension AppDatabase {
    func syncSummary() async throws -> SyncSummary {
        try await writer.read { db in
            let entryCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM entry") ?? 0
            let updatedAt = try String.fetchOne(db, sql: "SELECT MAX(updated_at) FROM entry")

            return SyncSummary(
                entryCount: entryCount,
                updatedAt: updatedAt.flatMap(Date.stored)
            )
        }
    }
}
