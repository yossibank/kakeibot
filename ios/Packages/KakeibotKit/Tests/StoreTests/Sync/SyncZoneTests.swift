import Core
import Foundation
@testable import Store
import Testing

struct SyncZoneTests {
    @Test
    func routesSharedWalletRecordToWalletZone() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))

        try await setup.database.startSharing(id)

        let change = try await setup.change(of: SyncKey(table: .wallet, id: walletID))

        #expect(change.saveZone == SyncZone.wallet(id))
        #expect(change.deleteZones == [])
    }

    @Test
    func deletesFromOwnZoneAfterMovingToWalletZone() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let key = SyncKey(table: .wallet, id: walletID)

        try await setup.database.saveSyncSystemFields([key.own: Data([1])])
        try await setup.database.startSharing(id)

        let change = try await setup.change(of: key)

        #expect(change.saveZone == SyncZone.wallet(id))
        #expect(change.deleteZones == [SyncZone.own])
        #expect(try await setup.database.syncSaveZone(for: key) == SyncZone.wallet(id))
    }

    @Test
    func listsEveryZoneOfDeletedRow() async throws {
        let setup = try await SyncTests.Setup()
        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")

        try await setup.database.saveSyncSystemFields([
            key.recordID(in: "Wallet-b"): Data([1]),
            key.own: Data([2])
        ])
        try await setup.execute("""
        INSERT INTO sync_change (table_name, record_id, version) VALUES ('no_spend_day', '2026-10-01', 1)
        """)

        let change = try await setup.change(of: key)

        #expect(change.isDeletion)
        #expect(change.saveZone == nil)
        #expect(change.deleteZones == [SyncZone.own, "Wallet-b"])
        #expect(try await setup.database.syncSaveZone(for: key) == SyncZone.own)
    }

    @Test
    func skipsDeletionFromOtherZone() async throws {
        let setup = try await SyncTests.Setup()
        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")
        let other = key.recordID(in: "Wallet-b")

        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        try await setup.database.saveSyncSystemFields([other: Data([1])])
        try await setup.database.applySyncChanges(saved: [], deleted: [key.own])

        #expect(try await setup.database.syncRecord(for: key) != nil)
        #expect(try await setup.database.syncSystemFields(for: other) == Data([1]))
    }

    @Test
    func appliesDeletionFromSameZone() async throws {
        let setup = try await SyncTests.Setup()
        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")
        let other = key.recordID(in: "Wallet-b")

        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        try await setup.database.saveSyncSystemFields([other: Data([1]), key.own: Data([2])])
        try await setup.database.applySyncChanges(saved: [], deleted: [other])

        #expect(try await setup.database.syncRecord(for: key) == nil)
        #expect(try await setup.database.syncSystemFields(for: other) == nil)
        #expect(try await setup.database.syncSystemFields(for: key.own) == Data([2]))
    }

    @Test
    func joinsShareWhenReceivingWalletZone() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let key = SyncKey(table: .wallet, id: walletID)
        let zoned = key.recordID(in: SyncZone.wallet(id))

        try await setup.database.applySyncChanges(
            saved: [],
            deleted: [],
            systemFields: [zoned: Data([1])]
        )
        try await setup.database.applySyncChanges(
            saved: [],
            deleted: [],
            systemFields: [zoned: Data([2])]
        )

        let count = try await setup.value("SELECT COUNT(*) FROM sync_share")

        #expect(count == "1")
    }

    @Test
    func ignoresWalletZoneOfMissingWallet() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let id = Wallet.ID()
        let key = SyncKey(table: .wallet, id: id.description)

        try await setup.database.applySyncChanges(
            saved: [],
            deleted: [],
            systemFields: [key.recordID(in: SyncZone.wallet(id)): Data([1])]
        )

        #expect(try await setup.value("SELECT COUNT(*) FROM sync_share") == "0")
    }

    @Test
    func joinsShareWithOwnerOfOtherAccount() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let zone = SyncZone.wallet(id)

        try await setup.joinForeignShare(of: walletID)

        #expect(try await setup.database.syncShareOwners() == [zone: "owner"])
    }

    @Test
    func endsForeignSharingWithoutQueueing() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))

        try await setup.joinForeignShare(of: walletID)
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        try await setup.database.endSharing(id)

        #expect(try await setup.pendingKeys() == [])
        #expect(try await setup.value("SELECT COUNT(*) FROM sync_share") == "0")
        #expect(try await setup.value("SELECT COUNT(*) FROM sync_record") == "0")
    }

    @Test
    func resetsOnlyForeignZonesForSharedDatabase() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        let own = SyncKey(table: .noSpendDay, id: "2026-10-01").own

        try await setup.joinForeignShare(of: walletID)
        try await setup.database.saveSyncSystemFields([own: Data([2])])
        try await setup.database.saveSyncEngineState(Data([3]), isShared: false)
        try await setup.database.saveSyncEngineState(Data([4]), isShared: true)

        try await setup.database.resetSync(isShared: true)

        #expect(try await setup.value("SELECT COUNT(*) FROM sync_record") == "1")
        #expect(try await setup.database.syncSystemFields(for: own) == Data([2]))
        #expect(try await setup.database.syncEngineState(isShared: false) == Data([3]))
        #expect(try await setup.database.syncEngineState(isShared: true) == nil)
    }

    @Test
    func keepsSharedWalletStateWhenTurningOff() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let shared = SyncKey(table: .wallet, id: walletID)
        let own = SyncKey(table: .noSpendDay, id: "2026-10-01")
        let zoned = shared.recordID(in: SyncZone.wallet(id))

        try await setup.database.startSharing(id)
        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        try await setup.database.saveSyncSystemFields([zoned: Data([1]), own.own: Data([2])])

        try await setup.database.turnOffSync()

        let keys = try await Set(setup.pendingKeys())

        #expect(keys.contains(shared))
        #expect(!keys.contains(own))
        #expect(try await setup.database.syncSystemFields(for: zoned) == Data([1]))
        #expect(try await setup.database.syncSystemFields(for: own.own) == nil)
    }

    @Test
    func queuesNothingForSharedZoneWhenReplacingLocal() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))

        try await setup.database.startSharing(id)
        try await setup.database.turnOnSyncReplacingLocal()

        #expect(try await setup.database.isSyncEnabled())
        #expect(try await setup.pendingKeys() == [])
        #expect(try await setup.value("SELECT COUNT(*) FROM wallet") == "0")
        #expect(try await setup.value("SELECT COUNT(*) FROM sync_record") == "0")
    }

    @Test
    func endsSharingAndQueuesRowsToOwnZone() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let key = SyncKey(table: .wallet, id: walletID)

        try await setup.database.startSharing(id)
        try await setup.database
            .saveSyncSystemFields([key.recordID(in: SyncZone.wallet(id)): Data([1])])
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        try await setup.database.endSharing(id)

        let keys = try await Set(setup.pendingKeys())
        let change = try await setup.change(of: key)
        let categories = try await setup.value("""
        SELECT COUNT(*) FROM category WHERE wallet_id = '\(walletID)'
        """)

        #expect(try await setup
            .value("SELECT COUNT(*) FROM wallet WHERE id = '\(walletID)'") == "1")
        #expect(try await setup.value("SELECT COUNT(*) FROM sync_share") == "0")
        #expect(try await setup.value("SELECT COUNT(*) FROM sync_record") == "0")
        #expect(keys.contains(key))
        #expect(change.saveZone == SyncZone.own)
        #expect(categories != "0")
        #expect(keys.count > 1)
    }

    @Test
    func endsSharingWithoutQueueingWhenSyncIsOff() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))

        try await setup.database.startSharing(id)
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        try await setup.database.endSharing(id)

        #expect(try await setup.pendingKeys() == [])
        #expect(try await setup.value("SELECT COUNT(*) FROM sync_share") == "0")
    }

    @Test
    func deletesAndRestoresWalletWithSharedCategories() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let categoryID = try await setup.categoryID()

        try await setup.execute("""
        INSERT INTO tag (id, category_id, name, sort_order, archived_at, created_at, updated_at)
        VALUES ('00000000-0000-4000-8000-000000000001', '\(categoryID)', '外食', 0, NULL,
                '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z')
        """)
        try await setup.database.startSharing(id)

        let counts = try await setup.sharedCounts(of: walletID)
        let deletion = try await setup.database.deleteWallet(id, at: Date(timeIntervalSince1970: 0))
        let deleted = try await setup.sharedCounts(of: walletID)

        try await setup.database.restore(deletion)

        let restored = try await setup.sharedCounts(of: walletID)

        #expect(counts.categories > 0)
        #expect(counts.tags > 0)
        #expect(deleted == SyncZoneTests.Counts(categories: 0, tags: 0, icons: 0))
        #expect(restored == counts)
    }

    @Test
    func keepsActiveUntilDeletedSharedWalletIsSent() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let key = SyncKey(table: .wallet, id: walletID)

        try await setup.database.startSharing(id)
        try await setup.database.deleteWallet(id, at: Date(timeIntervalSince1970: 0))

        let change = try await setup.change(of: key)
        let activity = try await setup.database.syncActivityUpdates().first { _ in true }

        #expect(change.isDeletion)
        #expect(try await setup.value("SELECT COUNT(*) FROM sync_share") == "0")
        #expect(activity?.isActive == true)
    }
}

private extension SyncTests.Setup {
    func change(of key: SyncKey) async throws -> SyncChange {
        try #require(await database.pendingSyncChanges().first { $0.key == key })
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

    func sharedCounts(of walletID: String) async throws -> SyncZoneTests.Counts {
        let categories = try await value(
            "SELECT COUNT(*) FROM category WHERE wallet_id = '\(walletID)'"
        )

        let tags = try await value("""
        SELECT COUNT(*) FROM tag JOIN category ON category.id = tag.category_id
        WHERE category.wallet_id = '\(walletID)'
        """)

        let icons = try await value("""
        SELECT COUNT(*) FROM icon WHERE id IN (
            SELECT icon_id FROM category WHERE wallet_id = '\(walletID)'
        )
        """)

        return SyncZoneTests.Counts(
            categories: Int(categories) ?? 0,
            tags: Int(tags) ?? 0,
            icons: Int(icons) ?? 0
        )
    }
}

extension SyncZoneTests {
    struct Counts: Equatable {
        let categories: Int
        let tags: Int
        let icons: Int
    }
}
