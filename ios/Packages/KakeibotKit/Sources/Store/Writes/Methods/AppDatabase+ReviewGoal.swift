import Core
import GRDB

public extension AppDatabase {
    func saveReviewGoal(_ goal: ReviewGoal) async throws {
        try await writer.write { db in
            try goal.save(db)
        }
    }
}
