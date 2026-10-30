import Foundation
import GRDB

public extension AppDatabase {
    func syncStatus() async throws -> SyncStatus {
        try await writer.read { db in
            try Self.syncStatus(in: db)
        }
    }

    func setSyncSendProblem(_ problem: SyncSendProblem?) async throws {
        try await writer.write { db in
            try db.execute(
                sql: "UPDATE sync_state SET send_problem = ?1 WHERE send_problem IS NOT ?1",
                arguments: [problem?.rawValue]
            )
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
        let row = try Row.fetchOne(
            db,
            sql: "SELECT enabled, stop_reason, send_problem FROM sync_state"
        )

        let reason: String? = row?["stop_reason"]
        let problem: String? = row?["send_problem"]
        let stopReason = reason.flatMap(SyncStopReason.init)
        let sendProblem = problem.flatMap(SyncSendProblem.init)

        return SyncStatus(
            isEnabled: row?["enabled"] ?? false,
            stopReason: stopReason,
            sendProblem: sendProblem
        )
    }
}
