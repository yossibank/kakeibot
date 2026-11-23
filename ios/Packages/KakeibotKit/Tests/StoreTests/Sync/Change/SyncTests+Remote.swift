import Foundation
@testable import Store
import Testing

extension SyncTests {
    @Test
    func appliesRemoteRowWithoutRecording() async throws {
        let source = try await Setup()
        let target = try await Setup(defaults: false)
        let walletID = try await source.walletID()
        let key = SyncKey(table: .wallet, id: walletID)
        let walletRecord = try #require(try await source.database.syncRecord(for: key))
        let iconRecord = try await source.iconRecord(of: key)

        try await target.database.applySyncChanges(
            saved: [walletRecord, iconRecord],
            deleted: [],
            at: StoreFixture.now
        )

        #expect(try await target.database.syncRecord(for: key) == walletRecord)
        #expect(try await target.pendingKeys() == [])
    }

    @Test
    func keepsNewerLocalRow() async throws {
        let setup = try await Setup()
        let walletID = try await setup.walletID()
        let key = SyncKey(table: .wallet, id: walletID)
        let local = try #require(try await setup.database.syncRecord(for: key))
        var values = local.values
        values["name"] = .text("old")
        values["updated_at"] = .text("2000-01-01T00:00:00Z")
        let remote = SyncRecord(key: key, values: values)

        try await setup.database.applySyncChanges(
            saved: [remote],
            deleted: [],
            at: StoreFixture.now
        )

        #expect(try await setup.database.syncRecord(for: key) == local)
    }

    @Test
    func waitsForMissingParent() async throws {
        let source = try await Setup()
        let target = try await Setup(defaults: false)
        let walletID = try await source.walletID()
        let key = SyncKey(table: .wallet, id: walletID)
        let walletRecord = try #require(try await source.database.syncRecord(for: key))
        let iconRecord = try await source.iconRecord(of: key)

        try await target.database.applySyncChanges(
            saved: [walletRecord],
            deleted: [],
            at: StoreFixture.now
        )
        let waiting = try await target.database.syncRecord(for: key)
        try await target.database.applySyncChanges(
            saved: [iconRecord],
            deleted: [],
            at: StoreFixture.now
        )
        let arrived = try await target.database.syncRecord(for: key)

        #expect(waiting == nil)
        #expect(arrived == walletRecord)
    }

    @Test
    func replacesRowWithSameUniqueKey() async throws {
        let setup = try await Setup()
        let iconID = try await setup.iconID()

        try await setup.execute("""
        INSERT INTO calendar_stamp (id, date, icon_id, created_at)
        VALUES ('local', '2026-10-01', '\(iconID)', '2026-10-02T00:00:00Z')
        """)

        let changes = try await setup.database.pendingSyncChanges()
        try await setup.database.removeSyncChanges(changes)
        let remoteKey = SyncKey(table: .calendarStamp, id: "remote")
        let local = SyncKey(table: .calendarStamp, id: "local")

        let remote = SyncRecord(
            key: remoteKey,
            values: [
                "date": .text("2026-10-01"),
                "icon_id": .text(iconID),
                "created_at": .text("2026-10-01T00:00:00Z")
            ]
        )

        try await setup.database.applySyncChanges(
            saved: [remote],
            deleted: [],
            at: StoreFixture.now
        )

        #expect(try await setup.database.syncRecord(for: local) == nil)
        #expect(try await setup.database.syncRecord(for: remote.key) != nil)
        #expect(try await setup.pendingKeys() == [local])
    }

    @Test
    func keepsParentWhenDeletionIsBlocked() async throws {
        let setup = try await Setup()
        let walletID = try await setup.walletID()
        let categoryID = try await setup.categoryID()

        try await setup.execute("""
        INSERT INTO entry (id, type, amount, date, category_id, wallet_id, created_at, updated_at)
        VALUES ('e', 'expense', 100, '2026-10-01', '\(categoryID)', '\(walletID)', 'x', 'x')
        """)

        let changes = try await setup.database.pendingSyncChanges()
        try await setup.database.removeSyncChanges(changes)
        let key = SyncKey(table: .wallet, id: walletID)

        try await setup.database.applySyncChanges(
            saved: [],
            deleted: [key.own],
            at: StoreFixture.now
        )

        #expect(try await setup.database.syncRecord(for: key) != nil)
        #expect(try await setup.pendingKeys() == [key])
    }

    @Test
    func deletesRemoteRowWithoutRecording() async throws {
        let setup = try await Setup()
        let insert = "INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')"
        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")
        try await setup.execute(insert)
        let changes = try await setup.database.pendingSyncChanges()
        try await setup.database.removeSyncChanges(changes)

        try await setup.database.applySyncChanges(
            saved: [],
            deleted: [key.own],
            at: StoreFixture.now
        )

        #expect(try await setup.database.syncRecord(for: key) == nil)
        #expect(try await setup.pendingKeys() == [])
    }

    @Test
    func keepsLocalDeletionNotYetSent() async throws {
        let setup = try await Setup()
        let insert = "INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')"
        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")
        let remote = SyncRecord(key: key, values: ["created_at": .text("x")])
        try await setup.execute(insert)
        let changes = try await setup.database.pendingSyncChanges()
        try await setup.database.removeSyncChanges(changes)

        try await setup.execute("DELETE FROM no_spend_day")
        try await setup.database.applySyncChanges(
            saved: [remote],
            deleted: [],
            at: StoreFixture.now
        )

        #expect(try await setup.database.syncRecord(for: key) == nil)
        #expect(try await setup.pendingKeys() == [key])
    }
}
