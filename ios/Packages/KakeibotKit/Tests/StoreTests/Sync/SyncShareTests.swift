import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct SyncShareTests {
    @Test
    func recordsChangesOnlyWhileSharing() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()

        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")
        let before = try await setup.pendingKeys()
        try await setup.execute("INSERT INTO sync_share (wallet_id) VALUES ('\(walletID)')")
        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-02', 'x')")
        let sharing = try await setup.pendingKeys()

        #expect(before == [])
        #expect(sharing == [SyncKey(table: .noSpendDay, id: "2026-10-02")])
    }

    @Test
    func stopsRecordingWhenShareIsRemoved() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()

        try await setup.execute("INSERT INTO sync_share (wallet_id) VALUES ('\(walletID)')")
        try await setup.execute("DELETE FROM sync_share")
        try await setup
            .execute("INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')")

        #expect(try await setup.pendingKeys() == [])
    }

    @Test
    func deletesShareWithWallet() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()

        try await setup.execute("INSERT INTO sync_share (wallet_id) VALUES ('\(walletID)')")
        try await setup.execute("DELETE FROM wallet WHERE id = '\(walletID)'")

        let count = try await setup.value("SELECT COUNT(*) FROM sync_share")

        #expect(count == "0")
    }

    @Test
    func routesRowsToSharedWalletZone() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let shared = try await setup.walletID()
        let other = try await setup.otherWalletID()
        let ids = try await setup.insertRoutingRows(shared: shared, other: other)

        try await setup.execute("INSERT INTO sync_share (wallet_id) VALUES ('\(shared)')")

        #expect(try await setup.zone(.wallet, shared) == shared)
        #expect(try await setup.zone(.wallet, other) == nil)
        #expect(try await setup.zone(.valuation, ids.valuation) == shared)
        #expect(try await setup.zone(.entry, ids.sharedEntry) == shared)
        #expect(try await setup.zone(.entry, ids.otherEntry) == nil)
        #expect(try await setup.zone(.entry, ids.transferIn) == shared)
        #expect(try await setup.zone(.entry, ids.transferOut) == shared)
        #expect(try await setup.zone(.category, ids.sharedCategory) == shared)
        #expect(try await setup.zone(.category, ids.ownCategory) == nil)
        #expect(try await setup.zone(.tag, ids.sharedTag) == shared)
        #expect(try await setup.zone(.tag, ids.ownTag) == nil)
        #expect(try await setup.zone(.icon, ids.sharedIcon) == shared)
        #expect(try await setup.zone(.icon, ids.categoryIcon) == shared)
        #expect(try await setup.zone(.icon, ids.ownIcon) == nil)
        #expect(try await setup.zone(.setting, "week_start") == nil)
        #expect(try await setup.zone(.entry, "missing") == nil)
    }

    @Test
    func copiesOwnCategoriesWhenStartingToShare() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let own = try await setup.ownCategories()
        let archived = try await setup.insertArchivedCategory()

        try await setup.database.startSharing(#require(Wallet.ID(walletID)))

        let copies = try await setup.sharedCategories(of: walletID)
        let ownAfter = try await setup.ownCategories()
        let icons = try await setup
            .value("SELECT COUNT(DISTINCT icon_id) FROM category WHERE wallet_id IS NOT NULL")
        let origins = Set(own.map(\.icon))

        #expect(copies.map(\.name) == own.map(\.name))
        #expect(copies.map(\.sortOrder) == own.map(\.sortOrder))
        #expect(!copies.map(\.id).contains(archived))
        #expect(Set(copies.map(\.id)).isDisjoint(with: own.map(\.id)))
        #expect(Set(copies.map(\.icon)).isDisjoint(with: origins))
        #expect(icons == String(own.count))
        #expect(ownAfter.map(\.id) == own.map(\.id))
    }

    @Test
    func copiesActiveTagsToCopiedCategory() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let categoryID = try await setup.categoryID()

        try await setup.execute("""
        INSERT INTO tag (id, category_id, name, sort_order, archived_at, created_at, updated_at)
        VALUES ('t1', '\(categoryID)', '外食', 0, NULL, 'x', 'x'),
               ('t2', '\(categoryID)', '古い', 1, 'x', 'x', 'x')
        """)

        try await setup.database.startSharing(#require(Wallet.ID(walletID)))

        let copied = try await setup.value("""
        SELECT tag.name FROM tag JOIN category ON category.id = tag.category_id
        WHERE category.wallet_id IS NOT NULL
        """)
        let count = try await setup.value("""
        SELECT COUNT(*) FROM tag JOIN category ON category.id = tag.category_id
        WHERE category.wallet_id IS NOT NULL
        """)
        let own = try await setup
            .value("SELECT COUNT(*) FROM tag WHERE category_id = '\(categoryID)'")

        #expect(copied == "外食")
        #expect(count == "1")
        #expect(own == "2")
    }

    @Test
    func movesEntriesOfSharedWalletToCopies() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let shared = try await setup.walletID()
        let other = try await setup.otherWalletID()
        let categoryID = try await setup.categoryID()

        try await setup.execute("""
        INSERT INTO tag (id, category_id, name, sort_order, archived_at, created_at, updated_at)
        VALUES ('t1', '\(categoryID)', '外食', 0, NULL, 'x', 'x')
        """)
        try await setup.insertEntry("in", wallet: shared, category: categoryID, tag: "t1")
        try await setup.insertEntry("out", wallet: other, category: categoryID, tag: "t1")

        try await setup.database.startSharing(#require(Wallet.ID(shared)))

        let moved = try await setup.value("SELECT category_id FROM entry WHERE id = 'in'")
        let movedTag = try await setup.value("SELECT tag_id FROM entry WHERE id = 'in'")
        let untouched = try await setup.value("SELECT category_id FROM entry WHERE id = 'out'")
        let untouchedTag = try await setup.value("SELECT tag_id FROM entry WHERE id = 'out'")
        let movedWallet = try await setup
            .value("SELECT wallet_id FROM category WHERE id = '\(moved)'")
        let tagParent = try await setup
            .value("SELECT category_id FROM tag WHERE id = '\(movedTag)'")

        #expect(moved != categoryID)
        #expect(movedWallet == shared)
        #expect(tagParent == moved)
        #expect(untouched == categoryID)
        #expect(untouchedTag == "t1")
    }

    @Test
    func copiesArchivedCategoriesUsedBySharedWallet() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let shared = try await setup.walletID()
        let archived = try await setup.insertArchivedCategory()

        try await setup.execute("""
        INSERT INTO tag (id, category_id, name, sort_order, archived_at, created_at, updated_at)
        VALUES ('t1', '\(archived)', '古い', 0, 'x', 'x', 'x')
        """)
        try await setup.insertEntry("in", wallet: shared, category: archived, tag: "t1")

        try await setup.database.startSharing(#require(Wallet.ID(shared)))

        let moved = try await setup.value("SELECT category_id FROM entry WHERE id = 'in'")
        let movedTag = try await setup.value("SELECT tag_id FROM entry WHERE id = 'in'")
        let movedWallet = try await setup
            .value("SELECT wallet_id FROM category WHERE id = '\(moved)'")
        let archivedAt = try await setup
            .value("SELECT archived_at FROM category WHERE id = '\(moved)'")
        let tagParent = try await setup
            .value("SELECT category_id FROM tag WHERE id = '\(movedTag)'")

        #expect(moved != archived)
        #expect(movedWallet == shared)
        #expect(archivedAt == "x")
        #expect(tagParent == moved)
    }

    @Test
    func queuesRowsOfSharedWallet() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let shared = try await setup.walletID()
        let categoryID = try await setup.categoryID()
        let iconID = try await setup.value("SELECT icon_id FROM wallet WHERE id = '\(shared)'")

        try await setup.execute("""
        INSERT INTO valuation (id, wallet_id, date, amount, created_at, updated_at)
        VALUES ('v1', '\(shared)', '2026-10-01', 100, 'x', 'x')
        """)
        try await setup.insertEntry("e1", wallet: shared, category: categoryID, tag: nil)
        try await setup.database.startSharing(#require(Wallet.ID(shared)))

        let keys = try await Set(setup.pendingKeys())
        let copies = try await setup.sharedCategories(of: shared)

        #expect(keys.contains(SyncKey(table: .wallet, id: shared)))
        #expect(keys.contains(SyncKey(table: .icon, id: iconID)))
        #expect(keys.contains(SyncKey(table: .valuation, id: "v1")))
        #expect(keys.contains(SyncKey(table: .entry, id: "e1")))
        #expect(copies.allSatisfy { keys.contains(SyncKey(table: .category, id: $0.id)) })
        #expect(copies.allSatisfy { keys.contains(SyncKey(table: .icon, id: $0.icon)) })
    }

    @Test
    func doesNothingWhenAlreadySharing() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))

        try await setup.database.startSharing(id)
        let first = try await setup.value("SELECT COUNT(*) FROM category")
        try await setup.database.startSharing(id)
        let second = try await setup.value("SELECT COUNT(*) FROM category")

        #expect(first == second)
    }

    @Test
    func hidesSharedCategoriesFromCategoryList() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let categoryID = try await setup.categoryID()
        let before = try await setup.database.categoryList()

        try await setup.execute("""
        INSERT INTO tag (id, category_id, name, sort_order, archived_at, created_at, updated_at)
        VALUES ('00000000-0000-4000-8000-000000000001', '\(categoryID)', '外食', 0, NULL,
                '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z')
        """)
        try await setup.database.startSharing(#require(Wallet.ID(walletID)))
        let after = try await setup.database.categoryList()
        let shared = try await setup.sharedCategories(of: walletID)

        #expect(!shared.isEmpty)
        #expect(after.categories.map(\.id) == before.categories.map(\.id))
        #expect(after.tags.map(\.id.description) == ["00000000-0000-4000-8000-000000000001"])
        #expect(after.categories.allSatisfy { $0.walletId == nil })
    }
}

private extension SyncTests.Setup {
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

    func otherWalletID() async throws -> String {
        try await value("SELECT id FROM wallet ORDER BY sort_order LIMIT 1 OFFSET 1")
    }

    func zone(
        _ table: SyncTable,
        _ id: String
    ) async throws -> String? {
        try await database.syncSharedWallet(for: SyncKey(table: table, id: id))?.description
    }

    func ownCategories() async throws -> [Category] {
        try await categories("wallet_id IS NULL")
    }

    func sharedCategories(of walletID: String) async throws -> [Category] {
        try await categories("wallet_id = '\(walletID)'")
    }

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
