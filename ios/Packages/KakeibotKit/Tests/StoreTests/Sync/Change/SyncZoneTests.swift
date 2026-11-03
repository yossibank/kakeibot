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
        let key = SyncKey(table: .wallet, id: walletID)

        try await setup.database.startSharing(id)
        let change = try await setup.change(of: key)

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
}

extension SyncTests.Setup {
    func change(of key: SyncKey) async throws -> SyncChange {
        let change = try await database.pendingSyncChanges().first { $0.key == key }
        return try #require(change)
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

        let categoryCount = Int(categories) ?? 0
        let tagCount = Int(tags) ?? 0
        let iconCount = Int(icons) ?? 0

        return SyncZoneTests.Counts(categories: categoryCount, tags: tagCount, icons: iconCount)
    }

    func insertSharedEntry() async throws -> SyncKey {
        let walletID = try await walletID()
        let categoryID = try await categoryID()

        try await execute("INSERT INTO sync_share (wallet_id) VALUES ('\(walletID)')")

        try await execute("""
        INSERT INTO entry (id, type, amount, category_id, wallet_id, date, created_at, updated_at)
        VALUES ('e-shared', 'expense', 1, '\(categoryID)', '\(walletID)', '2026-10-12', 'x', 'x')
        """)

        return SyncKey(table: .entry, id: "e-shared")
    }

    func sharedZone() async throws -> String {
        let walletID = try await walletID()
        return try SyncZone.wallet(#require(Wallet.ID(walletID)))
    }
}

extension SyncZoneTests {
    struct Counts: Equatable {
        let categories: Int
        let tags: Int
        let icons: Int
    }
}
