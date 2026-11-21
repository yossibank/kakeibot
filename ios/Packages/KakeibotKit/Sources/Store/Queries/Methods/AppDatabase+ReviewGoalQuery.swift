import Core
import GRDB

public extension AppDatabase {
    func reviewGoals(for period: String) async throws -> [ReviewGoal] {
        try await writer.read { db in
            try ReviewGoal
                .filter(Column("period") == period)
                .order(Column("created_at"))
                .fetchAll(db)
        }
    }
}
