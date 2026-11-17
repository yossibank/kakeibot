import Core
import GRDB

public extension AppDatabase {
    func saveReviewComment(_ comment: ReviewComment) async throws {
        try await writer.write { db in
            try comment.save(db)
        }
    }
}
