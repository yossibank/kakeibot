import Core
import GRDB

public extension AppDatabase {
    func claimReviewRequest(
        version: String,
        when isReady: @escaping @Sendable (EntryHistory) -> Bool
    ) async throws -> Bool {
        try await writer.write { db in
            guard try !Self.setting(.storeReviewOpened, in: db) else {
                return false
            }

            guard try Self.setting(.reviewRequestedVersion, in: db) != version else {
                return false
            }

            guard try isReady(Self.entryHistory(in: db)) else {
                return false
            }

            try Self.setSetting(.reviewRequestedVersion, to: version, in: db)
            try Self.setSetting(.storeReviewCardClosed, to: true, in: db)

            return true
        }
    }
}
