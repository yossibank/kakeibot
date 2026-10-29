import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct SyncLeaveTests {
    @Test
    func removesForeignWalletWithItsRows() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))

        try await setup.joinForeignShare(of: walletID)
        let categoryID = try await setup.insertSharedCategory(of: walletID)
        try await setup.execute("""
        INSERT INTO entry (id, type, amount, category_id, wallet_id, date, created_at, updated_at)
        VALUES (
            '\(UUID().uuidString.lowercased())', 'expense', 1, '\(categoryID)', '\(walletID)',
            '2026-10-12', '2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z'
        )
        """)
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        try await setup.database.endSharing(id)

        #expect(try await setup.count("wallet WHERE id = '\(walletID)'") == 0)
        #expect(try await setup.count("entry") == 0)
        #expect(try await setup.count("category WHERE wallet_id IS NOT NULL") == 0)
        #expect(try await setup.count("tag") == 0)
        #expect(try await setup.pendingKeys() == [])
    }

    @Test
    func keepsTransfersWithOwnWalletAsExpenseAndIncome() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        let ownID = try await setup.otherWalletID()
        let categoryID = try await setup.categoryID()
        let id = try #require(Wallet.ID(walletID))

        try await setup.joinForeignShare(of: walletID)
        try await setup.execute("""
        INSERT INTO entry (id, type, amount, wallet_id, to_wallet_id, date, created_at, updated_at)
        VALUES
            ('t-out', 'transfer', 100, '\(ownID)', '\(walletID)', '2026-10-12', 'x', 'x'),
            ('t-in', 'transfer', 50, '\(walletID)', '\(ownID)', '2026-10-12', 'x', 'x');
        INSERT INTO entry (
            id, type, amount, category_id, wallet_id, transfer_id, date, created_at, updated_at
        )
        VALUES ('fee', 'expense', 10, '\(categoryID)', '\(ownID)', 't-out', '2026-10-12', 'x', 'x')
        """)
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        try await setup.database.endSharing(id)

        let outgoing = try await setup.row(of: "t-out")
        let incoming = try await setup.row(of: "t-in")
        let pending = try await setup.pendingKeys()

        #expect(try await outgoing == [
            "expense",
            ownID,
            "",
            setup.setting("transfer_out_category_id")
        ])
        #expect(try await incoming == [
            "income",
            ownID,
            "",
            setup.setting("transfer_in_category_id")
        ])
        #expect(try await setup.count("entry WHERE id = 'fee' AND transfer_id IS NULL") == 1)
        #expect(pending.contains(SyncKey(table: .entry, id: "t-out")))
        #expect(pending.contains(SyncKey(table: .entry, id: "t-in")))
    }

    @Test
    func addsOnlyTransferCategoryInUse() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        let ownID = try await setup.otherWalletID()
        let id = try #require(Wallet.ID(walletID))

        try await setup.joinForeignShare(of: walletID)
        try await setup.execute("""
        INSERT INTO entry (id, type, amount, wallet_id, to_wallet_id, date, created_at, updated_at)
        VALUES ('t-out', 'transfer', 100, '\(ownID)', '\(walletID)', '2026-10-12', 'x', 'x')
        """)
        let before = try await setup.count("category")

        try await setup.database.endSharing(id)

        #expect(try await setup.count("category") == before + 1)
        #expect(try await setup.count("category WHERE name = '振替' AND kind = 'income'") == 0)
    }

    @Test
    func dropsTransfersWithOtherForeignWallet() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        let otherID = try await setup.otherWalletID()
        let id = try #require(Wallet.ID(walletID))

        try await setup.joinForeignShare(of: walletID)
        try await setup.joinForeignShare(of: otherID)
        try await setup.execute("""
        INSERT INTO entry (id, type, amount, wallet_id, to_wallet_id, date, created_at, updated_at)
        VALUES (
            '\(UUID().uuidString.lowercased())', 'transfer', 100, '\(walletID)', '\(otherID)',
            '2026-10-12', '2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z'
        )
        """)
        try await setup.database.removeSyncChanges(setup.database.pendingSyncChanges())

        try await setup.database.endSharing(id)

        #expect(try await setup.count("entry") == 0)
        #expect(try await setup.pendingKeys() == [])
    }
}

private extension SyncTests.Setup {
    func insertSharedCategory(of walletID: String) async throws -> String {
        let iconID = UUID().uuidString.lowercased()
        let categoryID = UUID().uuidString.lowercased()
        let tagID = UUID().uuidString.lowercased()

        try await execute("""
        INSERT INTO icon (id, glyph, color, created_at, updated_at)
        VALUES ('\(iconID)', 'food', '#000000', 'x', 'x');
        INSERT INTO category (id, kind, name, icon_id, sort_order, wallet_id, created_at, updated_at)
        VALUES ('\(categoryID)', 'expense', '食費', '\(iconID)', 0, '\(walletID)', 'x', 'x');
        INSERT INTO tag (id, category_id, name, sort_order, created_at, updated_at)
        VALUES ('\(tagID)', '\(categoryID)', '外食', 0, 'x', 'x')
        """)

        return categoryID
    }

    func count(_ from: String) async throws -> Int {
        try await Int(value("SELECT COUNT(*) FROM \(from)")) ?? -1
    }

    func row(of entryID: String) async throws -> [String] {
        try await database.writer.read { db in
            let row = try #require(try Row.fetchOne(
                db,
                sql: "SELECT type, wallet_id, to_wallet_id, category_id FROM entry WHERE id = ?",
                arguments: [entryID]
            ))

            return row.columnNames.map { (row[$0] as String?) ?? "" }
        }
    }

    func setting(_ key: String) async throws -> String {
        try await value("SELECT value FROM setting WHERE key = '\(key)'")
    }
}
