import Foundation
@testable import Store
import Testing

struct SyncSummaryTests {
    @Test
    func summarizesNoEntries() async throws {
        let setup = try await SyncTests.Setup()

        let summary = try await setup.database.syncSummary()

        #expect(summary == SyncSummary(entryCount: 0, updatedAt: nil))
    }

    @Test
    func countsEntriesAndFindsTheLatestUpdate() async throws {
        let setup = try await SyncTests.Setup()
        let wallet = try await setup.walletID()
        let category = try await setup.categoryID()
        try await setup.execute("""
        INSERT INTO entry (id, type, amount, category_id, wallet_id, date, created_at, updated_at)
        VALUES
            ('e1', 'expense', 1, '\(category)', '\(wallet)', '2026-10-28', 'x', '2026-10-30T08:12:00Z'),
            ('e2', 'expense', 1, '\(category)', '\(wallet)', '2026-10-28', 'x', '2026-10-28T12:04:00Z')
        """)

        let summary = try await setup.database.syncSummary()

        let latest = try Date("2026-10-30T08:12:00Z", strategy: .iso8601)
        #expect(summary == SyncSummary(entryCount: 2, updatedAt: latest))
    }
}
