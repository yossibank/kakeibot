import Foundation
@testable import Store
import Testing

struct SyncSwitchTests {
    @Test
    func turningOnQueuesAllRows() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let wallet = try await setup.walletID()
        let key = SyncKey(table: .wallet, id: wallet)

        try await setup.database.turnOnSync()

        #expect(try await setup.database.isSyncEnabled())
        #expect(try await setup.pendingKeys().contains(key))
    }

    @Test
    func replacingLocalRemovesSyncedRowsWithoutRecording() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let onboarding = "INSERT INTO setting (key, value) VALUES ('onboarding_completed', 'true')"
        let weekStart = "INSERT INTO setting (key, value) VALUES ('week_start', 'monday')"
        try await setup.execute(onboarding)
        try await setup.execute(weekStart)

        try await setup.database.turnOnSyncReplacingLocal()
        let keys = try await setup.value("SELECT group_concat(key) FROM setting")

        #expect(try await setup.database.isSyncEnabled())
        #expect(try await setup.pendingKeys() == [])
        #expect(try await setup.value("SELECT COUNT(*) FROM wallet") == "0")
        #expect(try await setup.value("SELECT COUNT(*) FROM category") == "0")
        #expect(keys == "onboarding_completed")
    }

    @Test
    func turningOffKeepsWaitingRowsOfSharedWallets() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()

        try await setup.joinForeignShare(of: walletID)

        try await setup.execute("""
        INSERT INTO sync_waiting (table_name, record_id, fields) VALUES
            ('entry', 'shared', '{"wallet_id":{"text":{"_0":"\(walletID)"}}}'),
            ('entry', 'own', '{"wallet_id":{"text":{"_0":"other"}}}')
        """)

        try await setup.database.turnOffSync()

        let waiting = try await setup.value("SELECT group_concat(record_id) FROM sync_waiting")

        #expect(waiting == "shared")
    }

    @Test
    func turningOffClearsSyncState() async throws {
        let setup = try await SyncTests.Setup()
        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")
        let insert = "INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')"
        try await setup.execute(insert)
        try await setup.database.saveSyncSystemFields([key.own: Data([1])])
        try await setup.database.saveSyncEngineState(Data([2]), isShared: false)

        try await setup.database.turnOffSync()

        #expect(try await setup.database.isSyncEnabled() == false)
        #expect(try await setup.pendingKeys() == [])
        #expect(try await setup.database.syncSystemFields(for: key.own) == nil)
        #expect(try await setup.database.syncEngineState(isShared: false) == nil)
    }

    @Test
    func keepsWhySyncStoppedForAccountChange() async throws {
        let setup = try await SyncTests.Setup()

        try await setup.database.turnOffSyncForAccountChange(.signedOut)
        let status = try await setup.database.syncStatus()

        #expect(status.isEnabled == false)
        #expect(status.stopReason == .signedOut)
    }

    @Test
    func keepsWhySyncStoppedWhenCloudIsReplaced() async throws {
        let setup = try await SyncTests.Setup()

        try await setup.database.turnOffSync(because: .cloudReplaced)
        let status = try await setup.database.syncStatus()

        #expect(status.isEnabled == false)
        #expect(status.stopReason == .cloudReplaced)
    }

    @Test
    func forgetsWhySyncStoppedWhenTurnedOnOrOffByHand() async throws {
        let setup = try await SyncTests.Setup()

        try await setup.database.turnOffSyncForAccountChange(.accountChanged)
        try await setup.database.turnOnSync()
        let turnedOn = try await setup.database.syncStatus()

        #expect(turnedOn.stopReason == nil)

        try await setup.database.turnOffSync(because: .cloudReplaced)
        try await setup.database.turnOffSync()
        let turnedOff = try await setup.database.syncStatus()

        #expect(turnedOff.stopReason == nil)

        try await setup.database.turnOffSync(because: .cloudReplaced)
        try await setup.database.turnOnSyncReplacingLocal()
        let replaced = try await setup.database.syncStatus()

        #expect(replaced.stopReason == nil)
    }

    @Test
    func keepsWhySendingIsStuckUntilItGoesThrough() async throws {
        let setup = try await SyncTests.Setup()

        try await setup.database.setSyncSendProblem(.quotaExceeded)
        let stuck = try await setup.database.syncStatus()
        try await setup.database.setSyncSendProblem(nil)
        let sent = try await setup.database.syncStatus()

        #expect(stuck.sendProblem == .quotaExceeded)
        #expect(sent.sendProblem == nil)
    }

    @Test
    func forgetsWhySendingIsStuckWhenTurnedOff() async throws {
        let setup = try await SyncTests.Setup()

        try await setup.database.setSyncSendProblem(.networkUnavailable)
        try await setup.database.turnOffSync()
        let status = try await setup.database.syncStatus()

        #expect(status.sendProblem == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func countsPendingUntilSent() async throws {
        let setup = try await SyncTests.Setup()
        var counts = setup.database.pendingSyncCountUpdates().makeAsyncIterator()
        let insert = "INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')"

        let first = try await counts.next()
        try await setup.execute(insert)
        let queued = try await counts.next()
        let changes = try await setup.database.pendingSyncChanges()
        try await setup.database.removeSyncChanges(changes)
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

        try await setup.execute("""
        INSERT INTO entry (id, type, amount, category_id, wallet_id, date, created_at, updated_at)
        VALUES ('e1', 'expense', 1, '\(category)', '\(wallet)', '2026-10-12', 'x', 'x')
        """)

        #expect(before == false)
        #expect(try await setup.database.hasEntries())
    }
}
