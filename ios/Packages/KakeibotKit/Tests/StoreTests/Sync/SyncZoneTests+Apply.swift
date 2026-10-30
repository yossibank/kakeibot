import Core
import Foundation
@testable import Store
import Testing

extension SyncZoneTests {
    @Test
    func skipsDeletionFromOtherZone() async throws {
        let setup = try await SyncTests.Setup()
        let key = try await setup.insertSharedEntry()
        let shared = try await key.recordID(in: setup.sharedZone())
        try await setup.database.saveSyncSystemFields([shared: Data([1]), key.own: Data([2])])

        try await setup.database.applySyncChanges(saved: [], deleted: [key.own])

        #expect(try await setup.database.syncRecord(for: key) != nil)
        #expect(try await setup.database.syncSystemFields(for: shared) == Data([1]))
        #expect(try await setup.database.syncSystemFields(for: key.own) == nil)
    }

    @Test
    func appliesDeletionFromSameZone() async throws {
        let setup = try await SyncTests.Setup()
        let key = try await setup.insertSharedEntry()
        let shared = try await key.recordID(in: setup.sharedZone())
        try await setup.database.saveSyncSystemFields([shared: Data([1]), key.own: Data([2])])

        try await setup.database.applySyncChanges(saved: [], deleted: [shared])

        #expect(try await setup.database.syncRecord(for: key) == nil)
        #expect(try await setup.database.syncSystemFields(for: shared) == nil)
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
        let zoned = key.recordID(in: SyncZone.wallet(id))

        try await setup.database.applySyncChanges(
            saved: [],
            deleted: [],
            systemFields: [zoned: Data([1])]
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
    func zoneMoveDeletionArrivingLaterKeepsRow() async throws {
        let device = try await SyncTests.Setup()
        let walletID = try await device.walletID()
        let categoryID = try await device.categoryID()
        let wallet = SyncKey(table: .wallet, id: walletID)
        let entry = SyncKey(table: .entry, id: "e1")

        try await device.execute("""
        INSERT INTO entry (id, type, amount, category_id, wallet_id, date, created_at, updated_at)
        VALUES ('e1', 'expense', 1, '\(categoryID)', '\(walletID)', '2026-10-12', 'x', 'x')
        """)

        try await device.database.saveSyncSystemFields([
            wallet.own: Data([1]),
            entry.own: Data([1])
        ])
        try await device.database.removeSyncChanges(device.database.pendingSyncChanges())

        let zone = try SyncZone.wallet(#require(Wallet.ID(walletID)))
        let walletRecord = try #require(try await device.database.syncRecord(for: wallet))
        let entryRecord = try #require(try await device.database.syncRecord(for: entry))

        try await device.database.applySyncChanges(
            saved: [walletRecord, entryRecord],
            deleted: [],
            systemFields: [
                wallet.recordID(in: zone): Data([2]),
                entry.recordID(in: zone): Data([2])
            ]
        )

        try await device.database.applySyncChanges(saved: [], deleted: [entry.own])

        #expect(try await device.database.syncRecord(for: entry) != nil)
    }
}
