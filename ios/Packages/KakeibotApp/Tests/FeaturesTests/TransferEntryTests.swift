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
        #expect(saved?.entry.id == entry?.id)
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
    func flagsAmountOverSourceBalance() async throws {
        let setup = try await Setup()
        let date = try #require(LocalDate("2026-10-01"))

        let income = EntryDraft(
            type: .income,
            amount: 3000,
            date: date,
            categoryId: setup.salary,
            walletId: setup.cash
        )

        try await setup.database.saveEntry(income, at: Date())

        let model = EntryModel(
            database: setup.database,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.press(.digit(3))
        model.press(.doubleZero)
        model.press(.digit(0))
        let atBalance = model.isOverSourceBalance
        model.press(.digit(1))

        #expect(!atBalance)
        #expect(model.isOverSourceBalance)
        #expect(model.canSave)
    }

    @Test
    func waitsForAmountBeforeWarningOverNegativeBalance() async throws {
        let setup = try await Setup()

        let card = try await setup.database.saveWallet(
            WalletDraft(
                kind: .card,
                name: "カード",
                mark: .glyph(.card),
                color: "#4A6FA5",
                initialBalance: -5000
            ),
            at: Date()
        )

        let model = EntryModel(
            database: setup.database,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.walletId = card.id
        let empty = model.isOverSourceBalance
        model.press(.digit(1))

        #expect(!empty)
        #expect(model.isOverSourceBalance)
    }

    @Test
    func paysOffLoanAtOnce() async throws {
        let setup = try await Setup()

        let loan = try await setup.database.saveWallet(
            WalletDraft(
                kind: .loan,
                name: "奨学金",
                mark: .glyph(.contract),
                color: "#4A6FA5",
                initialBalance: -100_000
            ),
            at: Date()
        )

        let model = EntryModel(
            database: setup.database,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.walletId = setup.bank
        model.toWalletId = loan.id
        let remaining = model.loanRemaining
        model.press(.digit(3))
        model.press(.doubleZero)
        model.press(.doubleZero)
        let current = model.currentLine(of: loan)
        let partial = model.afterLine(of: loan, isSource: false)
        model.payOffLoan()

        #expect(remaining == 100_000)
        #expect(current?.title == "今の残り")
        #expect(current?.amount == 100_000)
        #expect(partial?.title == "返済後")
        #expect(partial?.amount == 70000)
        #expect(model.amount == 100_000)
        #expect(model.afterLine(of: loan, isSource: false)?.amount == 0)
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

    @Test
    func listsRecentTransfersOnce() async throws {
        let setup = try await Setup()
        try await setup.saveTransfer(5000, from: setup.bank, to: setup.cash, at: 1)
        try await setup.saveTransfer(3000, from: setup.cash, to: setup.bank, at: 2)
        try await setup.saveTransfer(5000, from: setup.bank, to: setup.cash, at: 3)
        try await setup.saveTransfer(1000, from: setup.bank, to: setup.cash, at: 4)

        let model = EntryModel(
            database: setup.database,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        let amounts = model.recentTransfers.map(\.amount)
        let oldest = try #require(model.recentTransfers.last)
        model.applyTransfer(oldest)

        #expect(amounts == [1000, 5000, 3000])
        #expect(model.walletId == setup.cash)
        #expect(model.toWalletId == setup.bank)
        #expect(model.amount == 3000)
    }

    @Test
    func ordersFrequentRoutesByCount() async throws {
        let setup = try await Setup()
        try await setup.saveTransfer(3000, from: setup.cash, to: setup.bank, at: 1)
        try await setup.saveTransfer(5000, from: setup.bank, to: setup.cash, at: 2)
        try await setup.saveTransfer(1000, from: setup.bank, to: setup.cash, at: 3)

        let model = EntryModel(
            database: setup.database,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        let routes = model.frequentRoutes
        let last = try #require(routes.last)
        model.applyRoute(last)

        #expect(routes.map(\.walletId) == [setup.bank, setup.cash])
        #expect(model.walletId == setup.cash)
        #expect(model.toWalletId == setup.bank)
        #expect(model.routeText == "財布 → 銀行")
        #expect(model.sourceBalanceText?.hasPrefix("財布 残高 ") == true)
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

    func saveTransfer(
        _ amount: Int,
        from walletId: Wallet.ID,
        to toWalletId: Wallet.ID,
        at seconds: TimeInterval
    ) async throws {
        let draft = EntryDraft(
            type: .transfer,
            amount: amount,
            date: date,
            categoryId: nil,
            walletId: walletId,
            toWalletId: toWalletId
        )

        let now = Date(timeIntervalSince1970: 1_791_000_000 + seconds)
        _ = try await database.saveEntry(draft, at: now)
    }
}
