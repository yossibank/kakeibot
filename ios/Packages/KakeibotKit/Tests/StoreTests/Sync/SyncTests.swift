import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct SyncTests {
    @Test(.timeLimit(.minutes(1)))
    func notifiesChangeRecordedByTrigger() async throws {
        let setup = try await Setup()
        var updates = setup.database.syncChangeUpdates().makeAsyncIterator()

        let first: Void? = try await updates.next()
        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        let second: Void? = try await updates.next()

        #expect(first != nil)
        #expect(second != nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func notifiesQueuedChange() async throws {
        let setup = try await Setup()
        var updates = setup.database.syncChangeUpdates().makeAsyncIterator()

        let first: Void? = try await updates.next()
        try await setup.database.queueAllForSync()
        let second: Void? = try await updates.next()

        #expect(first != nil)
        #expect(second != nil)
    }

    @Test
    func recordsChangesOnlyWhenEnabled() async throws {
        let setup = try await Setup(enabled: false)

        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        let disabled = try await setup.pendingKeys()
        try await setup.database.setSyncEnabled(true)
        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-02', 'x')")
        let enabled = try await setup.pendingKeys()

        #expect(disabled == [])
        #expect(enabled == [SyncKey(table: .noSpendDay, id: "2026-10-02")])
    }

    @Test
    func skipsLocalSettings() async throws {
        let setup = try await Setup()

        try await setup
            .execute("INSERT INTO setting (key, value) VALUES ('onboarding_completed', 'true')")
        try await setup.execute("INSERT INTO setting (key, value) VALUES ('week_start', 'monday')")

        #expect(try await setup.pendingKeys() == [SyncKey(table: .setting, id: "week_start")])
    }

    @Test
    func keepsChangeMadeAfterReading() async throws {
        let setup = try await Setup()
        let walletID = try await setup.walletID()

        try await setup.execute("UPDATE wallet SET name = 'A' WHERE id = '\(walletID)'")
        let read = try await setup.database.pendingSyncChanges()
        try await setup.execute("UPDATE wallet SET name = 'B' WHERE id = '\(walletID)'")
        try await setup.database.removeSyncChanges(read)
        let afterNewer = try await setup.pendingKeys()
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())
        let afterAll = try await setup.pendingKeys()

        #expect(afterNewer == [SyncKey(table: .wallet, id: walletID)])
        #expect(afterAll == [])
    }

    @Test
    func queuesEverySyncedRow() async throws {
        let setup = try await Setup()

        try await setup.execute("INSERT INTO setting (key, value) VALUES ('entry_opened', 'true')")
        try await setup.database.queueAllForSync()
        let keys = try await setup.pendingKeys()

        #expect(try await keys.contains(SyncKey(table: .wallet, id: setup.walletID())))
        #expect(!keys.contains { $0.table == .setting })
    }

    @Test
    func appliesRemoteRowWithoutRecording() async throws {
        let source = try await Setup()
        let target = try await Setup(defaults: false)
        let key = try await SyncKey(table: .wallet, id: source.walletID())
        let walletRecord = try #require(try await source.database.syncRecord(for: key))
        let iconRecord = try await source.iconRecord(of: key)

        try await target.database.applySyncChanges(saved: [walletRecord, iconRecord], deleted: [])

        #expect(try await target.database.syncRecord(for: key) == walletRecord)
        #expect(try await target.pendingKeys() == [])
    }

    @Test
    func keepsNewerLocalRow() async throws {
        let setup = try await Setup()
        let key = try await SyncKey(table: .wallet, id: setup.walletID())
        let local = try #require(try await setup.database.syncRecord(for: key))
        var values = local.values

        values["name"] = .text("old")
        values["updated_at"] = .text("2000-01-01T00:00:00Z")
        try await setup.database.applySyncChanges(
            saved: [SyncRecord(key: key, values: values)],
            deleted: []
        )

        #expect(try await setup.database.syncRecord(for: key) == local)
    }

    @Test
    func waitsForMissingParent() async throws {
        let source = try await Setup()
        let target = try await Setup(defaults: false)
        let key = try await SyncKey(table: .wallet, id: source.walletID())
        let walletRecord = try #require(try await source.database.syncRecord(for: key))
        let iconRecord = try await source.iconRecord(of: key)

        try await target.database.applySyncChanges(saved: [walletRecord], deleted: [])
        let waiting = try await target.database.syncRecord(for: key)

        try await target.database.applySyncChanges(saved: [iconRecord], deleted: [])
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
        VALUES ('local', '2026-10-01', '\(iconID)', 'x')
        """)

        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        let remote = SyncRecord(
            key: SyncKey(table: .calendarStamp, id: "remote"),
            values: [
                "date": .text("2026-10-01"),
                "icon_id": .text(iconID),
                "created_at": .text("x")
            ]
        )

        try await setup.database.applySyncChanges(saved: [remote], deleted: [])

        let local = SyncKey(table: .calendarStamp, id: "local")

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

        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        let key = SyncKey(table: .wallet, id: walletID)

        try await setup.database.applySyncChanges(saved: [], deleted: [key.own])

        #expect(try await setup.database.syncRecord(for: key) != nil)
        #expect(try await setup.pendingKeys() == [key])
    }

    @Test
    func deletesRemoteRowWithoutRecording() async throws {
        let setup = try await Setup()

        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")

        try await setup.database.applySyncChanges(saved: [], deleted: [key.own])

        #expect(try await setup.database.syncRecord(for: key) == nil)
        #expect(try await setup.pendingKeys() == [])
    }

    @Test
    func keepsLocalDeletionNotYetSent() async throws {
        let setup = try await Setup()

        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")
        let remote = SyncRecord(key: key, values: ["created_at": .text("x")])

        try await setup.execute("DELETE FROM no_spend_day")
        try await setup.database.applySyncChanges(saved: [remote], deleted: [])

        #expect(try await setup.database.syncRecord(for: key) == nil)
        #expect(try await setup.pendingKeys() == [key])
    }

    @Test
    func savesEngineState() async throws {
        let setup = try await Setup()
        let state = Data([1, 2, 3])
        let shared = Data([4])

        try await setup.database.saveSyncEngineState(state, isShared: false)
        try await setup.database.saveSyncEngineState(shared, isShared: true)

        #expect(try await setup.database.syncEngineState(isShared: false) == state)
        #expect(try await setup.database.syncEngineState(isShared: true) == shared)
    }

    @Test
    func marksChangeOfMissingRowAsDeletion() async throws {
        let setup = try await Setup()

        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        let saved = try await setup.database.pendingSyncChanges().map(\.isDeletion)
        try await setup.execute("DELETE FROM no_spend_day")
        let deleted = try await setup.database.pendingSyncChanges().map(\.isDeletion)

        #expect(saved == [false])
        #expect(deleted == [true])
    }

    @Test
    func savesSystemFieldsWithRemoteRows() async throws {
        let setup = try await Setup()

        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        let saved = SyncKey(table: .noSpendDay, id: "2026-10-02")
        let deleted = SyncKey(table: .noSpendDay, id: "2026-10-01")
        let remote = SyncRecord(key: saved, values: ["created_at": .text("x")])
        let fields = Data([1])

        try await setup.database.saveSyncSystemFields([deleted.own: fields])
        try await setup.database.applySyncChanges(
            saved: [remote],
            deleted: [deleted.own],
            systemFields: [saved.own: fields]
        )

        #expect(try await setup.database.syncSystemFields(for: saved.own) == fields)
        #expect(try await setup.database.syncSystemFields(for: deleted.own) == nil)
    }

    @Test
    func savesAndResetsSystemFields() async throws {
        let setup = try await Setup()
        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")
        let other = SyncKey(table: .noSpendDay, id: "2026-10-02")
        let fields = Data([1, 2, 3])

        try await setup.database.saveSyncSystemFields([key.own: fields, other.own: fields])
        try await setup.database.saveSyncEngineState(Data([4]), isShared: false)
        let saved = try await setup.database.syncSystemFields(for: key.own)

        try await setup.database.removeSyncSystemFields([key.own])
        let removed = try await setup.database.syncSystemFields(for: key.own)

        try await setup.database.resetSync(isShared: false)

        #expect(saved == fields)
        #expect(removed == nil)
        #expect(try await setup.database.syncSystemFields(for: other.own) == nil)
        #expect(try await setup.database.syncEngineState(isShared: false) == nil)
    }
}

extension SyncTests {
    struct Setup {
        let database: AppDatabase
    }
}

extension SyncKey {
    var own: SyncRecordID {
        SyncRecordID(key: self, zoneName: SyncZone.own)
    }

    func recordID(in zoneName: String) -> SyncRecordID {
        SyncRecordID(key: self, zoneName: zoneName)
    }
}

extension SyncTests.Setup {
    init(
        enabled: Bool = true,
        defaults: Bool = true
    ) async throws {
        let database = try AppDatabase.inMemory()

        if defaults {
            try database.insertDefaultsIfEmpty(at: Date(timeIntervalSince1970: 1_791_000_000))
        }

        try await database.setSyncEnabled(enabled)

        self.init(database: database)
    }

    func execute(_ sql: String) async throws {
        try await database.writer.write { db in
            try db.execute(sql: sql)
        }
    }

    func joinForeignShare(of walletID: String) async throws {
        let id = try #require(Wallet.ID(walletID))
        let zone = SyncZone.wallet(id)
        let zoned = SyncKey(table: .wallet, id: walletID).recordID(in: zone)

        try await database.applySyncChanges(
            saved: [],
            deleted: [],
            systemFields: [zoned: Data([1])],
            owners: [zone: "owner"]
        )
    }

    func pendingKeys() async throws -> [SyncKey] {
        try await database.pendingSyncChanges().map(\.key)
    }

    func walletID() async throws -> String {
        try await value("SELECT id FROM wallet ORDER BY sort_order")
    }

    func otherWalletID() async throws -> String {
        try await value("SELECT id FROM wallet ORDER BY sort_order LIMIT 1 OFFSET 1")
    }

    func categoryID() async throws -> String {
        try await value("SELECT id FROM category WHERE kind = 'expense' ORDER BY sort_order")
    }

    func iconID() async throws -> String {
        try await value("SELECT id FROM icon ORDER BY id")
    }

    func iconRecord(of wallet: SyncKey) async throws -> SyncRecord {
        let id = try await value("SELECT icon_id FROM wallet WHERE id = '\(wallet.id)'")
        return try #require(try await database.syncRecord(for: SyncKey(table: .icon, id: id)))
    }

    func value(_ sql: String) async throws -> String {
        let value = try await database.writer.read { db in
            try String.fetchOne(db, sql: sql)
        }

        return try #require(value)
    }
}
