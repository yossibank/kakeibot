import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct EntryModelTransferTests {
    @Test
    func startsWithTwoDifferentWallets() async throws {
        let setup = try await Setup()
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()

        #expect(model.state.payment.walletId == setup.cash)
        #expect(model.state.payment.toWalletId == setup.bank)
        #expect(model.state.category.id == nil)
        #expect(model.output.walletTitle == "振替元")
        #expect(!model.output.isChanged)
    }

    @Test
    func loadedDraftSwitchedToTransferMatchesFreshTransfer() async throws {
        let setup = try await Setup()
        let fresh = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )
        let draft = EntryModel(database: setup.database, clock: .system, date: setup.date)

        await fresh.load()
        await draft.load()
        draft.select(.transfer)

        #expect(draft.state.type == .transfer)
        #expect(draft.state.payment.walletId == fresh.state.payment.walletId)
        #expect(draft.state.payment.toWalletId == fresh.state.payment.toWalletId)
        #expect(draft.state.category.id == fresh.state.category.id)
        #expect(!draft.output.isChanged)
    }

    @Test
    func savesSwappedTransfer() async throws {
        let setup = try await Setup()
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.state.press(.digit(3))
        model.state.press(.doubleZero)
        model.state.press(.doubleZero)
        model.swapWallets()

        let title = model.output.saveTitle
        let saved = await model.save()
        let entry = try setup.database.snapshot().entries.first

        #expect(title == "振り替える")
        #expect(saved?.entry.id == entry?.id)
        #expect(entry?.type == .transfer)
        #expect(entry?.walletId == setup.bank)
        #expect(entry?.toWalletId == setup.cash)
        #expect(entry?.categoryId == nil)
    }

    @Test
    func keepsCategoryWhenComingBackFromTransfer() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()
        let category = model.state.category.id

        model.select(.transfer)
        let transferCategory = model.state.category.id
        let destination = model.state.payment.toWalletId
        model.select(.expense)

        #expect(transferCategory == nil)
        #expect(destination == setup.bank)
        #expect(model.state.category.id == category)
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
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.state.press(.digit(5))
        let bank = try #require(model.output.wallet(setup.bank))
        let balance = model.output.balance(of: bank)
        model.state.setDestination(nil)

        #expect(balance == 5000)
        #expect(model.output.saveTitle == "振替先を選んでください")
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
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.state.press(.digit(3))
        model.state.press(.doubleZero)
        model.state.press(.digit(0))
        let atBalance = model.output.isOverSourceBalance
        model.state.press(.digit(1))

        #expect(!atBalance)
        #expect(model.output.isOverSourceBalance)
        #expect(model.output.canSave)
    }

    @Test
    func waitsForAmountBeforeWarningOverNegativeBalance() async throws {
        let setup = try await Setup()

        let wallet = WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#4A6FA5",
            initialBalance: -5000
        )

        let card = try await setup.database.save(wallet, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.setWallet(card.id)
        let empty = model.output.isOverSourceBalance
        model.state.press(.digit(1))

        #expect(!empty)
        #expect(model.output.isOverSourceBalance)
    }

    @Test
    func paysOffLoanAtOnce() async throws {
        let setup = try await Setup()

        let wallet = WalletDraft(
            kind: .loan,
            name: "奨学金",
            mark: .glyph(.contract),
            color: "#4A6FA5",
            initialBalance: -100_000
        )

        let loan = try await setup.database.save(wallet, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.setWallet(setup.bank)
        model.state.setDestination(loan.id)
        let remaining = model.output.loanRemaining
        model.state.press(.digit(3))
        model.state.press(.doubleZero)
        model.state.press(.doubleZero)
        let current = model.output.currentLine(of: loan)
        let partial = model.output.afterLine(of: loan, isSource: false)
        model.payOffLoan()

        #expect(remaining == 100_000)
        #expect(current?.title == "今の残り")
        #expect(current?.amount == 100_000)
        #expect(partial?.title == "返済後")
        #expect(partial?.amount == 70000)
        #expect(model.output.amount == 100_000)
        #expect(model.output.afterLine(of: loan, isSource: false)?.amount == 0)
    }

    @Test
    func reportsSameWallet() async throws {
        let setup = try await Setup()
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.state.press(.digit(5))
        model.state.setDestination(model.state.payment.walletId)

        #expect(!model.output.canSave)
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
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        let amounts = model.output.recentTransfers.map(\.amount)
        let oldest = try #require(model.output.recentTransfers.last)
        model.applyTransfer(oldest)

        #expect(amounts == [1000, 5000, 3000])
        #expect(model.state.payment.walletId == setup.cash)
        #expect(model.state.payment.toWalletId == setup.bank)
        #expect(model.output.amount == 3000)
    }

    @Test
    func ordersFrequentRoutesByCount() async throws {
        let setup = try await Setup()
        try await setup.saveTransfer(3000, from: setup.cash, to: setup.bank, at: 1)
        try await setup.saveTransfer(5000, from: setup.bank, to: setup.cash, at: 2)
        try await setup.saveTransfer(1000, from: setup.bank, to: setup.cash, at: 3)
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        let routes = model.output.frequentRoutes
        let last = try #require(routes.last)
        model.applyRoute(last)

        #expect(routes.map(\.walletId) == [setup.bank, setup.cash])
        #expect(model.state.payment.walletId == setup.cash)
        #expect(model.state.payment.toWalletId == setup.bank)
    }

    @Test
    func choosesAnotherSourceWhenHidden() async throws {
        let setup = try await Setup()
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        try await setup.database.setHidden(setup.cash, isHidden: true, at: Date())
        await model.reloadWallets()

        #expect(model.state.payment.walletId != setup.cash)
        #expect(model.state.payment.walletId != nil)
        #expect(model.state.payment.walletId != model.state.payment.toWalletId)
    }

    @Test
    func choosesAnotherDestinationWhenHidden() async throws {
        let setup = try await Setup()
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        try await setup.database.setHidden(setup.bank, isHidden: true, at: Date())
        await model.reloadWallets()

        #expect(model.state.payment.walletId == setup.cash)
        #expect(model.state.payment.toWalletId != setup.bank)
        #expect(model.state.payment.toWalletId != setup.cash)
    }
}

extension EntryModelTransferTests {
    struct Setup {
        let database: AppDatabase
        let date: LocalDate
        let cash: Wallet.ID
        let bank: Wallet.ID
        let salary: EntryCategory.ID
    }
}

extension EntryModelTransferTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let date = try #require(LocalDate("2026-10-12"))

        try database.insertDefaultsIfEmpty(at: Date())

        let options = try await database.entryOptions()

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
        let now = Date(timeIntervalSince1970: 1_791_000_000 + seconds)

        let draft = EntryDraft(
            type: .transfer,
            amount: amount,
            date: date,
            categoryId: nil,
            walletId: walletId,
            toWalletId: toWalletId
        )

        _ = try await database.saveEntry(draft, at: now)
    }
}
