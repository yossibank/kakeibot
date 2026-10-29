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
        let expected = SyncKey(table: .noSpendDay, id: "2026-10-02")
        let first = "INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')"
        let second = "INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-02', 'x')"

        try await setup.execute(first)
        let before = try await setup.pendingKeys()
        try await setup.execute("INSERT INTO sync_share (wallet_id) VALUES ('\(walletID)')")
        try await setup.execute(second)
        let sharing = try await setup.pendingKeys()

        #expect(before == [])
        #expect(sharing == [expected])
    }

    @Test
    func stopsRecordingWhenShareIsRemoved() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let insert = "INSERT INTO no_spend_day (date, created_at) VALUES ('2026-10-01', 'x')"
        try await setup.execute("INSERT INTO sync_share (wallet_id) VALUES ('\(walletID)')")
        try await setup.execute("DELETE FROM sync_share")

        try await setup.execute(insert)

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
        let sharedWalletZone = try await setup.zone(.wallet, shared)
        let otherWalletZone = try await setup.zone(.wallet, other)
        let valuationZone = try await setup.zone(.valuation, ids.valuation)
        let sharedEntryZone = try await setup.zone(.entry, ids.sharedEntry)
        let otherEntryZone = try await setup.zone(.entry, ids.otherEntry)
        let transferInZone = try await setup.zone(.entry, ids.transferIn)
        let transferOutZone = try await setup.zone(.entry, ids.transferOut)
        let sharedCategoryZone = try await setup.zone(.category, ids.sharedCategory)
        let ownCategoryZone = try await setup.zone(.category, ids.ownCategory)
        let sharedTagZone = try await setup.zone(.tag, ids.sharedTag)
        let ownTagZone = try await setup.zone(.tag, ids.ownTag)
        let sharedIconZone = try await setup.zone(.icon, ids.sharedIcon)
        let categoryIconZone = try await setup.zone(.icon, ids.categoryIcon)
        let ownIconZone = try await setup.zone(.icon, ids.ownIcon)
        let settingZone = try await setup.zone(.setting, "week_start")
        let missingZone = try await setup.zone(.entry, "missing")

        #expect(sharedWalletZone == shared)
        #expect(otherWalletZone == nil)
        #expect(valuationZone == shared)
        #expect(sharedEntryZone == shared)
        #expect(otherEntryZone == nil)
        #expect(transferInZone == shared)
        #expect(transferOutZone == shared)
        #expect(sharedCategoryZone == shared)
        #expect(ownCategoryZone == nil)
        #expect(sharedTagZone == shared)
        #expect(ownTagZone == nil)
        #expect(sharedIconZone == shared)
        #expect(categoryIconZone == shared)
        #expect(ownIconZone == nil)
        #expect(settingZone == nil)
        #expect(missingZone == nil)
    }

    @Test
    func copiesOwnCategoriesWhenStartingToShare() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let own = try await setup.ownCategories()
        let archived = try await setup.insertArchivedCategory()

        try await setup.database.startSharing(id)
        let copies = try await setup.sharedCategories(of: walletID)
        let ownAfter = try await setup.ownCategories()

        let icons = try await setup.value("""
        SELECT COUNT(DISTINCT icon_id) FROM category WHERE wallet_id IS NOT NULL
        """)

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
        let id = try #require(Wallet.ID(walletID))
        let categoryID = try await setup.categoryID()

        try await setup.execute("""
        INSERT INTO tag (id, category_id, name, sort_order, archived_at, created_at, updated_at)
        VALUES ('t1', '\(categoryID)', '外食', 0, NULL, 'x', 'x'),
               ('t2', '\(categoryID)', '古い', 1, 'x', 'x', 'x')
        """)

        try await setup.database.startSharing(id)

        let copied = try await setup.value("""
        SELECT tag.name FROM tag JOIN category ON category.id = tag.category_id
        WHERE category.wallet_id IS NOT NULL
        """)

        let count = try await setup.value("""
        SELECT COUNT(*) FROM tag JOIN category ON category.id = tag.category_id
        WHERE category.wallet_id IS NOT NULL
        """)

        let own = try await setup.value("""
        SELECT COUNT(*) FROM tag WHERE category_id = '\(categoryID)'
        """)

        #expect(copied == "外食")
        #expect(count == "1")
        #expect(own == "2")
    }

    @Test
    func movesEntriesOfSharedWalletToCopies() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let shared = try await setup.walletID()
        let id = try #require(Wallet.ID(shared))
        let other = try await setup.otherWalletID()
        let categoryID = try await setup.categoryID()

        try await setup.execute("""
        INSERT INTO tag (id, category_id, name, sort_order, archived_at, created_at, updated_at)
        VALUES ('t1', '\(categoryID)', '外食', 0, NULL, 'x', 'x')
        """)

        try await setup.insertEntry("in", wallet: shared, category: categoryID, tag: "t1")
        try await setup.insertEntry("out", wallet: other, category: categoryID, tag: "t1")

        try await setup.database.startSharing(id)
        let moved = try await setup.value("SELECT category_id FROM entry WHERE id = 'in'")
        let movedTag = try await setup.value("SELECT tag_id FROM entry WHERE id = 'in'")
        let untouched = try await setup.value("SELECT category_id FROM entry WHERE id = 'out'")
        let untouchedTag = try await setup.value("SELECT tag_id FROM entry WHERE id = 'out'")

        let movedWallet = try await setup.value("""
        SELECT wallet_id FROM category WHERE id = '\(moved)'
        """)

        let tagParent = try await setup.value("""
        SELECT category_id FROM tag WHERE id = '\(movedTag)'
        """)

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
        let id = try #require(Wallet.ID(shared))
        let archived = try await setup.insertArchivedCategory()

        try await setup.execute("""
        INSERT INTO tag (id, category_id, name, sort_order, archived_at, created_at, updated_at)
        VALUES ('t1', '\(archived)', '古い', 0, 'x', 'x', 'x')
        """)

        try await setup.insertEntry("in", wallet: shared, category: archived, tag: "t1")

        try await setup.database.startSharing(id)
        let moved = try await setup.value("SELECT category_id FROM entry WHERE id = 'in'")
        let movedTag = try await setup.value("SELECT tag_id FROM entry WHERE id = 'in'")

        let movedWallet = try await setup.value("""
        SELECT wallet_id FROM category WHERE id = '\(moved)'
        """)

        let archivedAt = try await setup.value("""
        SELECT archived_at FROM category WHERE id = '\(moved)'
        """)

        let tagParent = try await setup.value("""
        SELECT category_id FROM tag WHERE id = '\(movedTag)'
        """)

        #expect(moved != archived)
        #expect(movedWallet == shared)
        #expect(archivedAt == "x")
        #expect(tagParent == moved)
    }

    @Test
    func queuesRowsOfSharedWallet() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let shared = try await setup.walletID()
        let id = try #require(Wallet.ID(shared))
        let categoryID = try await setup.categoryID()
        let iconID = try await setup.value("SELECT icon_id FROM wallet WHERE id = '\(shared)'")
        let walletKey = SyncKey(table: .wallet, id: shared)
        let iconKey = SyncKey(table: .icon, id: iconID)
        let valuationKey = SyncKey(table: .valuation, id: "v1")
        let entryKey = SyncKey(table: .entry, id: "e1")

        try await setup.execute("""
        INSERT INTO valuation (id, wallet_id, date, amount, created_at, updated_at)
        VALUES ('v1', '\(shared)', '2026-10-01', 100, 'x', 'x')
        """)

        try await setup.insertEntry("e1", wallet: shared, category: categoryID, tag: nil)

        try await setup.database.startSharing(id)
        let keys = try await Set(setup.pendingKeys())
        let copies = try await setup.sharedCategories(of: shared)
        let categoryKeys = copies.map { SyncKey(table: .category, id: $0.id) }
        let copiedIconKeys = copies.map { SyncKey(table: .icon, id: $0.icon) }

        #expect(keys.contains(walletKey))
        #expect(keys.contains(iconKey))
        #expect(keys.contains(valuationKey))
        #expect(keys.contains(entryKey))
        #expect(keys.isSuperset(of: categoryKeys))
        #expect(keys.isSuperset(of: copiedIconKeys))
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
        let id = try #require(Wallet.ID(walletID))
        let categoryID = try await setup.categoryID()
        let before = try await setup.database.categoryList()

        try await setup.execute("""
        INSERT INTO tag (id, category_id, name, sort_order, archived_at, created_at, updated_at)
        VALUES ('00000000-0000-4000-8000-000000000001', '\(categoryID)', '外食', 0, NULL,
                '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z')
        """)

        try await setup.database.startSharing(id)
        let after = try await setup.database.categoryList()
        let shared = try await setup.sharedCategories(of: walletID)

        #expect(!shared.isEmpty)
        #expect(after.categories.map(\.id) == before.categories.map(\.id))
        #expect(after.tags.map(\.id.description) == ["00000000-0000-4000-8000-000000000001"])
        #expect(after.categories.allSatisfy { $0.walletId == nil })
    }

    @Test
    func hidesSharedCategoriesFromEntryOptions() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let categoryID = try await setup.categoryID()
        let before = try await setup.database.entryOptions()

        try await setup.execute("""
        INSERT INTO tag (id, category_id, name, sort_order, archived_at, created_at, updated_at)
        VALUES ('00000000-0000-4000-8000-000000000001', '\(categoryID)', '外食', 0, NULL,
                '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z')
        """)

        try await setup.database.startSharing(id)
        let after = try await setup.database.entryOptions()

        #expect(after.expenseCategories.map(\.id) == before.expenseCategories.map(\.id))
        #expect(after.incomeCategories.map(\.id) == before.incomeCategories.map(\.id))
        #expect(after.tags.map(\.id.description) == ["00000000-0000-4000-8000-000000000001"])
    }

    @Test
    func listsOwnWalletsWithShareState() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let shared = try await setup.walletID()
        let other = try await setup.otherWalletID()

        try await setup.execute("INSERT INTO sync_share (wallet_id) VALUES ('\(shared)')")
        let before = try await setup.walletShares()

        try await setup.execute("""
        INSERT INTO sync_share (wallet_id, owner_name) VALUES ('\(other)', '_owner')
        """)

        let after = try await setup.walletShares()

        #expect(before.first?.wallet.id.description == shared)
        #expect(before.first?.isShared == true)
        #expect(before.first?.icon != nil)
        #expect(before.filter(\.isShared).count == 1)
        #expect(after.map(\.wallet.id.description).contains(other) == false)
        #expect(after.count == before.count - 1)
    }

    @Test
    func listsHiddenWalletOnlyWhileSharing() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()

        try await setup.execute("""
        UPDATE wallet SET archived_at = created_at WHERE id = '\(walletID)'
        """)

        let hidden = try await setup.walletShares()
        try await setup.execute("INSERT INTO sync_share (wallet_id) VALUES ('\(walletID)')")
        let sharing = try await setup.walletShares()

        #expect(hidden.map(\.wallet.id.description).contains(walletID) == false)
        #expect(sharing.map(\.wallet.id.description).contains(walletID))
    }

    @Test
    func listsJoinedWalletsWithOwner() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let own = try await setup.walletID()
        let joined = try await setup.otherWalletID()

        try await setup.execute("INSERT INTO sync_share (wallet_id) VALUES ('\(own)')")

        try await setup.execute("""
        INSERT INTO sync_share (wallet_id, owner_name) VALUES ('\(joined)', '_owner')
        """)

        let shares = try await setup.joinedShares()

        #expect(shares.map(\.wallet.id.description) == [joined])
        #expect(shares.first?.ownerName == "_owner")
        #expect(shares.first?.icon != nil)
    }
}
