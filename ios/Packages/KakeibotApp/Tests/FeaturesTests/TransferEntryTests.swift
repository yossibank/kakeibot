import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct TransferEntryTests {
    @Test
    func startsWithTwoDifferentWallets() async throws {
        let setup = try await Setup()

        let model = EntryModel(
            database: setup.database,
            date: setup.date,
            type: .transfer
        )
        await model.load()

        #expect(model.walletId == setup.cash)
        #expect(model.toWalletId == setup.bank)
        #expect(model.categoryId == nil)
        #expect(model.walletTitle == "振替元")
        #expect(!model.isChanged)
    }

    @Test
    func savesSwappedTransfer() async throws {
        let setup = try await Setup()

        let model = EntryModel(
            database: setup.database,
            date: setup.date,
            type: .transfer
        )
        await model.load()
        model.press(.digit(3))
        model.press(.doubleZero)
        model.press(.doubleZero)
        model.swapWallets()

        let title = model.saveTitle
        let saved = await model.save()
        let entry = try setup.database.snapshot().entries.first

        #expect(title == "¥30,000 を振り替える")
        #expect(saved)
        #expect(entry?.type == .transfer)
        #expect(entry?.walletId == setup.bank)
        #expect(entry?.toWalletId == setup.cash)
        #expect(entry?.categoryId == nil)
    }

    @Test
    func keepsCategoryWhenComingBackFromTransfer() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let category = model.categoryId

        model.select(.transfer)
        let transferCategory = model.categoryId
        let destination = model.toWalletId
        model.select(.expense)

        #expect(transferCategory == nil)
        #expect(destination == setup.bank)
        #expect(model.categoryId == category)
    }

    @Test
    func showsBalancesAndMissingDestination() async throws {
        let setup = try await Setup()
        let date = try #require(LocalDate("2026-10-01"))

        let income = EntryDraft(
            type: .income,
            amount: 5000,
            date: date,
            categoryId: setup.salary,
            walletId: setup.bank
        )

        try await setup.database.saveEntry(income, at: Date())

        let model = EntryModel(
            database: setup.database,
            date: setup.date,
            type: .transfer
        )
        await model.load()
        model.press(.digit(5))
        let bank = try #require(model.wallet(setup.bank))
        let balance = model.balance(of: bank)
        model.toWalletId = nil

        #expect(balance == 5000)
        #expect(model.saveTitle == "振替先を選んでください")
    }

    @Test
    func reportsSameWallet() async throws {
        let setup = try await Setup()

        let model = EntryModel(
            database: setup.database,
            date: setup.date,
            type: .transfer
        )
        await model.load()
        model.press(.digit(5))
        model.toWalletId = model.walletId

        #expect(!model.canSave)
    }
}

extension TransferEntryTests {
    struct Setup {
        let database: AppDatabase
        let date: LocalDate
        let cash: Wallet.ID
        let bank: Wallet.ID
        let salary: EntryCategory.ID
    }
}

extension TransferEntryTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let date = try #require(LocalDate("2026-10-12"))

        self.init(
            database: database,
            date: date,
            cash: options.wallets[0].id,
            bank: options.wallets[1].id,
            salary: options.incomeCategories[0].id
        )
    }
}
