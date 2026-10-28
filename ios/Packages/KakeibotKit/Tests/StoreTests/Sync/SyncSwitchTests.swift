import Foundation
@testable import Store
import Testing

struct SyncSwitchTests {
    @Test
    func turningOnQueuesAllRows() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let wallet = try await setup.walletID()

        try await setup.database.turnOnSync()

        #expect(try await setup.database.isSyncEnabled())
        #expect(try await setup.pendingKeys().contains(SyncKey(table: .wallet, id: wallet)))
    }

    @Test
    func replacingLocalRemovesSyncedRowsWithoutRecording() async throws {
        let setup = try await SyncTests.Setup(enabled: false)

        try await setup
            .execute("INSERT INTO setting (key, value) VALUES ('onboarding_completed', 'true')")
        try await setup.execute("INSERT INTO setting (key, value) VALUES ('week_start', 'monday')")

        try await setup.database.turnOnSyncReplacingLocal()

        #expect(try await setup.database.isSyncEnabled())
        #expect(try await setup.pendingKeys() == [])
        #expect(try await setup.value("SELECT COUNT(*) FROM wallet") == "0")
        #expect(try await setup.value("SELECT COUNT(*) FROM category") == "0")
        #expect(try await setup
            .value("SELECT group_concat(key) FROM setting") == "onboarding_completed")
    }

    @Test
    func turningOffClearsSyncState() async throws {
        let setup = try await SyncTests.Setup()
        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")

        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        try await setup.database.saveSyncSystemFields([key: Data([1])])
        try await setup.database.saveSyncEngineState(Data([2]))

        try await setup.database.turnOffSync()

        #expect(try await setup.database.isSyncEnabled() == false)
        #expect(try await setup.pendingKeys() == [])
        #expect(try await setup.database.syncSystemFields(for: key) == nil)
        #expect(try await setup.database.syncEngineState() == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func countsPendingUntilSent() async throws {
        let setup = try await SyncTests.Setup()
        var counts = setup.database.pendingSyncCountUpdates().makeAsyncIterator()

        let first = try await counts.next()
        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        let queued = try await counts.next()
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())
        let sent = try await counts.next()

        #expect(first == 0)
        #expect(queued == 1)
        #expect(sent == 0)
    }

    @Test
    func findsEntries() async throws {
        let setup = try await SyncTests.Setup()
        let wallet = try await setup.walletID()
        let category = try await setup.categoryID()
        let before = try await setup.database.hasEntries()

        try await setup.execute(
            """
            INSERT INTO entry (id, type, amount, category_id, wallet_id, date, created_at, updated_at)
            VALUES ('e1', 'expense', 1, '\(category)', '\(wallet)', '2026-10-12', 'x', 'x')
            """
        )

        #expect(before == false)
        #expect(try await setup.database.hasEntries())
    }
}
