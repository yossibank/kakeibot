import Core
import GRDB

public extension AppDatabase {
    func reviewComment(for period: String) async throws -> ReviewComment? {
        try await writer.read { db in
            try ReviewComment.fetchOne(db, key: period)
        }
    }
}
