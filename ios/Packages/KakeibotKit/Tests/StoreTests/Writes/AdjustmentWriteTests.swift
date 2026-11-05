import Core
import Foundation
import Store
import Testing

struct AdjustmentWriteTests {
    @Test
    func movesBalanceWithoutEntries() async throws {
        let setup = try await Setup()

        try await setup.addExpense(3000)
        try await setup.adjust(-1200)
        let list = try await setup.database.entryList()
        let entries = setup.entries(in: list)
        let balance = setup.wallet.balance(with: entries, adjustments: list.adjustments)

        #expect(list.adjustments.map(\.amount) == [-1200])
        #expect(entries.count == 1)
        #expect(list.days.map(\.expenseTotal) == [3000])
        #expect(balance == setup.wallet.initialBalance - 4200)
    }

    @Test
    func savesNothingForZero() async throws {
        let setup = try await Setup()

        let adjustment = try await setup.adjust(0)
        let list = try await setup.database.entryList()

        #expect(adjustment == nil)
        #expect(list.adjustments.isEmpty)
    }

    @Test
    func restoresDeletedAdjustment() async throws {
        let setup = try await Setup()
        try await setup.adjust(500)
        let saved = try await setup.database.entryList().adjustments
        let id = try #require(saved.first?.id)

        let deletion = try #require(try await setup.database.deleteAdjustment(id))
        let deleted = try await setup.database.entryList().adjustments
        try await setup.database.restore(deletion)
        let restored = try await setup.database.entryList().adjustments

        #expect(deletion.subject?.kind == .adjustment)
        #expect(deleted.isEmpty)
        #expect(restored == saved)
    }

    @Test
    func returnsNoDeletionForMissingAdjustment() async throws {
        let setup = try await Setup()

        let deletion = try await setup.database.deleteAdjustment(Adjustment.ID())

        #expect(deletion == nil)
    }

    @Test
    func keepsMonthTotals() async throws {
        let setup = try await Setup()
        try await setup.addExpense(3000)
        let before = try await setup.database.monthOverview(on: setup.day)

        try await setup.adjust(-5000)
        try await setup.adjust(8000)
        let after = try await setup.database.monthOverview(on: setup.day)

        #expect(after.monthExpense == before.monthExpense)
        #expect(after.monthIncome == before.monthIncome)
        #expect(after.todayExpense == before.todayExpense)
        #expect(after.list?.days == before.list?.days)
    }

    @Test
    func deletesAndRestoresWithWallet() async throws {
        let setup = try await Setup()
        let draft = WalletDraft(
            kind: .cash,
            name: "封筒",
            mark: .text("封"),
            color: "#BF4040",
            initialBalance: 0
        )

        let wallet = try await setup.database.saveWallet(draft, at: setup.now)
        try await setup.database.saveAdjustment(700, of: wallet.id, on: setup.day, at: setup.now)

        let deletion = try await setup.database.deleteWallet(wallet.id, at: setup.now)
        let deleted = try await setup.database.entryList().adjustments
        try await setup.database.restore(deletion)
        let restored = try await setup.database.entryList().adjustments

        #expect(deleted.isEmpty)
        #expect(restored.map(\.walletId) == [wallet.id])
    }
}

extension AdjustmentWriteTests {
    struct Setup {
        let database: AppDatabase
        let wallet: Wallet
        let category: EntryCategory.ID
        let day: LocalDate
        let now = Date(timeIntervalSince1970: 1_791_000_000)
    }
}

extension AdjustmentWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date(timeIntervalSince1970: 1_791_000_000))
        let options = try await database.entryOptions()
        let wallet = try #require(options.wallets.first)
        let category = try #require(options.expenseCategories.first?.id)
        let day = try #require(LocalDate("2026-10-23"))

        self.init(
            database: database,
            wallet: wallet,
            category: category,
            day: day
        )
    }

    func addExpense(_ amount: Int) async throws {
        let draft = EntryDraft(
            type: .expense,
            amount: amount,
            date: day,
            categoryId: category,
            walletId: wallet.id
        )

        try await database.saveEntry(draft, at: now)
    }

    @discardableResult
    func adjust(_ amount: Int) async throws -> Adjustment? {
        try await database.saveAdjustment(amount, of: wallet.id, on: day, at: now)
    }

    func entries(in list: EntryList) -> [Entry] {
        list.days.flatMap(\.entries)
    }
}
