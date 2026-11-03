import Core
import Foundation
import GRDB
@testable import Store
import Testing

extension SyncShareTests {
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
