import Core
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct WalletListModelTests {
    @Test
    func reordersShownWallets() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let model = WalletListModel(database: database, clock: .system)
        await model.load()
        let bank = try #require(model.output.shown.last)

        model.move(bank.id, to: 0)
        let moving = model.output.shown.map(\.name)
        await model.finishMoving()
        let options = try await database.entryOptions()

        #expect(moving == ["銀行", "財布"])
        #expect(model.state.movingOrder == nil)
        #expect(options.wallets.map(\.name) == ["銀行", "財布"])
    }

    @Test
    func splitsHiddenWalletsAndShowsBalance() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let bank = try #require(options.wallets.last)
        try await database.setHidden(bank.id, isHidden: true, at: Date())

        let model = WalletListModel(database: database, clock: .system)
        await model.load()
        let cash = try #require(model.output.shown.first)

        #expect(model.output.shown.map(\.name) == ["財布"])
        #expect(model.output.hidden.map(\.name) == ["銀行"])
        #expect(model.output.balance(of: cash, through: ScreenClock.system.today) == 0)
    }

    @Test
    func leavesOutFutureEntriesFromBalance() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let cash = try #require(options.wallets.first)
        let today = LocalDate(Date(), in: .current)
        let futureDate = today.adding(days: 3)

        let income = EntryDraft(
            type: .income,
            amount: 1000,
            date: today,
            categoryId: options.incomeCategories[0].id,
            walletId: cash.id
        )

        let future = EntryDraft(
            type: .expense,
            amount: 400,
            date: futureDate,
            categoryId: options.expenseCategories[0].id,
            walletId: cash.id
        )

        try await database.saveEntry(income, at: Date())
        try await database.saveEntry(future, at: Date())
        let model = WalletListModel(database: database, clock: .system)
        await model.load()

        #expect(model.output.balance(of: cash, through: ScreenClock.system.today) == 1000)
    }

    @Test
    func confirmsHidingWalletWithOnlyFutureEntries() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let cash = try #require(options.wallets.first)
        let bank = try #require(options.wallets.last)
        let today = LocalDate(Date(), in: .current)
        let futureDate = today.adding(days: 3)

        let future = EntryDraft(
            type: .expense,
            amount: 400,
            date: futureDate,
            categoryId: options.expenseCategories[0].id,
            walletId: cash.id
        )

        try await database.saveEntry(future, at: Date())
        let model = WalletListModel(database: database, clock: .system)
        await model.load()

        #expect(model.output.balance(of: cash, through: ScreenClock.system.today) == 0)
        #expect(model.output.needsHideConfirmation(of: cash))
        #expect(!model.output.needsHideConfirmation(of: bank))
    }

    @Test
    func hidesWalletButKeepsTheLastOne() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let model = WalletListModel(database: database, clock: .system)
        await model.load()
        let cash = try #require(model.output.shown.first)
        let bank = try #require(model.output.shown.last)

        model.move(bank.id, to: 0)
        await model.hide(bank.id)
        let shown = model.output.shown.map(\.name)
        let hidden = model.output.hidden.map(\.name)
        await model.hide(cash.id)

        #expect(shown == ["財布"])
        #expect(hidden == ["銀行"])
        #expect(model.state.movingOrder == nil)
        #expect(model.output.shown.map(\.name) == ["財布"])
        #expect(model.state.errorNotice.message == "最後の 1 つの口座は非表示にできません")
    }

    @Test
    func showsHiddenWallet() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let model = WalletListModel(database: database, clock: .system)
        await model.load()
        let bank = try #require(model.output.shown.last)
        await model.hide(bank.id)

        await model.show(bank.id)

        #expect(model.output.hidden.isEmpty)
        #expect(model.output.shown.map(\.name) == ["財布", "銀行"])
    }
}
