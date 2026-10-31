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

        do {
            guard try await database.setting(.reviewRequestedVersion) != version else {
                return false
            }

            let history = try await database.entryHistory()

            guard isReady(history, at: now) else {
                return false
            }

            try await database.setSetting(.reviewRequestedVersion, to: version)

            return true
        } catch {
            return false
        }
    }
}

private extension StoreReviewRequest {
    func isReady(
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
