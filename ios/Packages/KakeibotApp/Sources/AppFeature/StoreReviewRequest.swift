import Features
import Foundation
import Store

struct StoreReviewRequest: Sendable {
    let database: AppDatabase
    let version: String
    let calendar: Calendar

    init(
        database: AppDatabase,
        version: String = Bundle.main.shortVersion,
        calendar: Calendar = .current
    ) {
        self.database = database
        self.version = version
        self.calendar = calendar
    }
}

extension StoreReviewRequest {
    static let minimumEntries = 30
    static let minimumDays = 7

    func shouldAsk(
        after change: EntryChange,
        at now: Date
    ) async -> Bool {
        guard case .recorded = change.kind else {
            return false
        }

        let claimed = try? await database.claimReviewRequest(version: version) { history in
            isReady(history, at: now)
        }

        return claimed ?? false
    }
}

private extension StoreReviewRequest {
    nonisolated func isReady(
        _ history: EntryHistory,
        at now: Date
    ) -> Bool {
        guard
            history.count >= Self.minimumEntries,
            let first = history.firstCreatedAt
        else {
            return false
        }

        let days = calendar.dateComponents([.day], from: first, to: now).day ?? 0

        return days >= Self.minimumDays
    }
}
