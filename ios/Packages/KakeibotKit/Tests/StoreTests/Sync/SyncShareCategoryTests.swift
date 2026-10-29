import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct SyncShareCategoryTests {
    @Test
    func savesSharedWalletEntryWithSharedCategory() async throws {
        let setup = try await Setup()

        let entry = try await setup.database.saveEntry(
            setup.draft(wallet: setup.shared),
            at: Date()
        )

        let category = try await setup.category(of: entry.id)

        #expect(category == Category(name: "食費", walletID: setup.shared.description))
    }

    @Test
    func movesEntryCategoryWhenWalletChangesToShared() async throws {
        let setup = try await Setup()
        let entry = try await setup.database.saveEntry(setup.draft(wallet: setup.other), at: Date())

        _ = try await setup.database.changeEntries(
            [entry.id],
            to: .wallet(setup.shared),
            at: Date()
        )

        let moved = try await setup.category(of: entry.id)

        _ = try await setup.database.changeEntries(
            [entry.id],
            to: .wallet(setup.other),
            at: Date()
        )

        let back = try await setup.category(of: entry.id)

        #expect(moved == Category(name: "食費", walletID: setup.shared.description))
        #expect(back == Category(name: "食費", walletID: nil))
    }

    @Test
    func usesSharedCategoryForFeeOfSharedTransfer() async throws {
        let setup = try await Setup()

        let draft = try EntryDraft(
            type: .transfer,
            amount: 1000,
            date: #require(LocalDate("2026-10-12")),
            categoryId: nil,
            walletId: setup.shared,
            toWalletId: setup.other,
            fee: 110
        )

        let transfer = try await setup.database.saveEntry(draft, at: Date())
        let fee = try #require(try await setup.database.fee(of: transfer.id))
        let category = try await setup.category(of: fee.id)

        #expect(category.walletID == setup.shared.description)
    }

    @Test
    func copiesMissingCategoryIntoSharedWallet() async throws {
        let setup = try await Setup()

        try await setup.execute("""
        INSERT INTO category (id, kind, name, icon_id, sort_order, created_at, updated_at)
        SELECT '11111111-1111-4111-8111-111111111111', 'expense', '新しい', icon_id, 99, created_at, updated_at
        FROM category LIMIT 1
        """)

        let categoryID = try #require(EntryCategory.ID("11111111-1111-4111-8111-111111111111"))
        var draft = try setup.draft(wallet: setup.shared)
        draft.categoryId = categoryID

        let entry = try await setup.database.saveEntry(draft, at: Date())
        let category = try await setup.category(of: entry.id)

        #expect(category == Category(name: "新しい", walletID: setup.shared.description))
    }
}

extension SyncShareCategoryTests {
    struct Category: Equatable {
        let name: String
        let walletID: String?
    }

    struct Setup {
        let base: SyncTests.Setup
        let shared: Wallet.ID
        let other: Wallet.ID
        let food: EntryCategory.ID
    }
}

extension SyncShareCategoryTests.Setup {
    var database: AppDatabase {
        base.database
    }

    init() async throws {
        let base = try await SyncTests.Setup(enabled: false)
        let shared = try #require(try await Wallet.ID(base.walletID()))
        let other = try #require(try await Wallet.ID(base.otherWalletID()))
        let food = try #require(try await EntryCategory.ID(base.value(
            "SELECT id FROM category WHERE name = '食費'"
        )))

        try await base.database.startSharing(shared)

        self.init(base: base, shared: shared, other: other, food: food)
    }

    func draft(wallet: Wallet.ID) throws -> EntryDraft {
        try EntryDraft(
            type: .expense,
            amount: 500,
            date: #require(LocalDate("2026-10-12")),
            categoryId: food,
            walletId: wallet
        )
    }

    func execute(_ sql: String) async throws {
        try await base.execute(sql)
    }

    func category(of entryID: Entry.ID) async throws -> SyncShareCategoryTests.Category {
        let join = """
        FROM entry JOIN category ON category.id = entry.category_id
        WHERE entry.id = '\(entryID)'
        """

        let name = try await base.value("SELECT category.name \(join)")
        let walletID = try await base.value("SELECT IFNULL(category.wallet_id, '') \(join)")

        return SyncShareCategoryTests.Category(
            name: name,
            walletID: walletID.isEmpty ? nil : walletID
        )
    }
}
