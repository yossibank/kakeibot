import Core
import Foundation
import GRDB
@testable import Store
import Testing

extension SyncTests.Setup {
    struct Category {
        let id: String
        let name: String
        let sortOrder: Int
        let icon: String
    }

    struct RoutingIDs {
        let valuation = "v1"
        let sharedEntry = "e-shared"
        let otherEntry = "e-other"
        let transferIn = "e-in"
        let transferOut = "e-out"
        let sharedCategory = "c-shared"
        let ownCategory = "c-own"
        let sharedTag = "t-shared"
        let ownTag = "t-own"
        let sharedIcon: String
        let categoryIcon = "i-category"
        let ownIcon = "i-own"
    }

    func walletShares() async throws -> [WalletShare] {
        for try await shares in database.walletShareUpdates() {
            return shares
        }

        return []
    }

    func joinedShares() async throws -> [JoinedShare] {
        for try await shares in database.joinedShareUpdates() {
            return shares
        }

        return []
    }

    func zone(
        _ table: SyncTable,
        _ id: String
    ) async throws -> String? {
        let key = SyncKey(table: table, id: id)
        return try await database.syncSharedWallet(for: key)?.description
    }

    func ownCategories() async throws -> [Category] {
        try await categories("wallet_id IS NULL")
    }

    func sharedCategories(of walletID: String) async throws -> [Category] {
        try await categories("wallet_id = '\(walletID)'")
    }

    func insertArchivedCategory() async throws -> String {
        let iconID = try await iconID()

        try await execute("""
        INSERT INTO category (id, kind, name, icon_id, sort_order, archived_at, created_at, updated_at)
        VALUES ('c-archived', 'expense', '古い', '\(iconID)', 99, 'x', 'x', 'x')
        """)

        return "c-archived"
    }

    func insertEntry(
        _ id: String,
        wallet: String,
        category: String,
        tag: String?
    ) async throws {
        let tagValue = tag.map { "'\($0)'" } ?? "NULL"

        try await execute("""
        INSERT INTO entry (id, type, amount, category_id, tag_id, wallet_id, date, created_at, updated_at)
        VALUES ('\(id)', 'expense', 1, '\(category)', \(tagValue), '\(wallet)', '2026-10-12', 'x', 'x')
        """)
    }

    func insertRoutingRows(
        shared: String,
        other: String
    ) async throws -> RoutingIDs {
        let walletIcon = try await value("SELECT icon_id FROM wallet WHERE id = '\(shared)'")
        let ids = RoutingIDs(sharedIcon: walletIcon)
        let categoryID = try await categoryID()

        try await execute("""
        INSERT INTO icon (id, emoji, color, created_at, updated_at)
        VALUES ('\(ids.categoryIcon)', 'a', 'x', 'x', 'x'), ('\(ids.ownIcon)', 'b', 'x', 'x', 'x')
        """)

        try await execute("""
        INSERT INTO category (id, kind, name, icon_id, sort_order, wallet_id, created_at, updated_at)
        VALUES ('\(ids.sharedCategory)', 'expense', 'x', '\(ids.categoryIcon)', 50, '\(shared)', 'x', 'x'),
               ('\(ids.ownCategory)', 'expense', 'y', '\(ids.ownIcon)', 51, NULL, 'x', 'x')
        """)

        try await execute("""
        INSERT INTO tag (id, category_id, name, sort_order, created_at, updated_at)
        VALUES ('\(ids.sharedTag)', '\(ids.sharedCategory)', 'a', 0, 'x', 'x'),
               ('\(ids.ownTag)', '\(ids.ownCategory)', 'b', 0, 'x', 'x')
        """)

        try await execute("""
        INSERT INTO valuation (id, wallet_id, date, amount, created_at, updated_at)
        VALUES ('\(ids.valuation)', '\(shared)', '2026-10-01', 100, 'x', 'x')
        """)

        try await insertEntry(ids.sharedEntry, wallet: shared, category: categoryID, tag: nil)
        try await insertEntry(ids.otherEntry, wallet: other, category: categoryID, tag: nil)

        try await execute("""
        INSERT INTO entry (id, type, amount, wallet_id, to_wallet_id, date, created_at, updated_at)
        VALUES ('\(ids.transferIn)', 'transfer', 1, '\(other)', '\(shared)', '2026-10-12', 'x', 'x'),
               ('\(ids.transferOut)', 'transfer', 1, '\(shared)', '\(other)', '2026-10-12', 'x', 'x')
        """)

        return ids
    }
}

private extension SyncTests.Setup {
    func categories(_ condition: String) async throws -> [Category] {
        try await database.writer.read { db in
            try Row.fetchAll(
                db,
                sql: "SELECT * FROM category WHERE \(condition) AND archived_at IS NULL ORDER BY sort_order, name"
            ).map { row in
                Category(
                    id: row["id"],
                    name: row["name"],
                    sortOrder: row["sort_order"],
                    icon: row["icon_id"]
                )
            }
        }
    }
}
