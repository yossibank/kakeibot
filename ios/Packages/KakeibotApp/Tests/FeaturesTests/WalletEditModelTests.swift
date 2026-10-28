import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct WalletEditModelTests {
    @Test
    func addsCardWithNegativeBalance() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database)
        model.name = "楽天カード"
        model.kind = .card
        model.press(.digit(3))
        model.press(.digit(8))
        model.press(.doubleZero)
        model.press(.digit(0))

        let saved = try #require(await model.save())
        let list = try await setup.database.entryList()
        let icon = try #require(list.icons[saved.iconId])

        #expect(model.calculator.amount == 38000)
        #expect(saved.initialBalance == -38000)
        #expect(saved.kind == .card)
        #expect(icon.glyph == .card)
    }

    @Test
    func namesWhatIsMissingOnSaveButton() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let model = WalletEditModel(database: setup.database)

        let editing = WalletEditModel(
            database: setup.database,
            editing: bank.id
        )

        await editing.load()

        let empty = model.saveTitle
        model.name = "楽天カード"
        let named = model.saveTitle
        model.icon.markKind = .emoji
        let noMark = model.saveTitle

        #expect(empty == "名前を入れてください")
        #expect(named == "追加する")
        #expect(noMark == "アイコンを選んでください")
        #expect(editing.saveTitle == "変更を保存")
    }

    @Test
    func tracksChangesFromStart() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database)
        let start = model.isChanged

        model.name = "楽天カード"
        let named = model.isChanged

        model.name = ""
        let cleared = model.isChanged

        model.kind = .bank
        let kindChanged = model.isChanged

        #expect(!start)
        #expect(named)
        #expect(!cleared)
        #expect(kindChanged)
    }

    @Test
    func keepsChosenGlyphWhenKindChanges() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database)

        model.kind = .bank
        let followed = model.icon.glyph
        model.icon.glyph = .coin
        model.kind = .card

        #expect(followed == .bank)
        #expect(model.icon.glyph == .coin)
    }

    @Test
    func followsSignWhenKindChanges() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database)

        model.kind = .card
        let card = model.isNegative
        model.kind = .bank
        let bank = model.isNegative
        model.isNegative = true
        model.kind = .cash

        #expect(card)
        #expect(!bank)
        #expect(model.isNegative)
    }

    @Test
    func locksKindAcrossDebtOnlyWithRecords() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let bank = try await setup.wallet(named: "銀行")
        let cash = try await setup.wallet(named: "財布")

        let draft = try EntryDraft(
            type: .expense,
            amount: 500,
            date: #require(LocalDate("2026-10-10")),
            categoryId: options.expenseCategories[0].id,
            walletId: bank.id
        )

        try await setup.database.saveEntry(draft, at: Date())
        let used = WalletEditModel(database: setup.database, editing: bank.id)
        let unused = WalletEditModel(database: setup.database, editing: cash.id)
        await used.load()
        await unused.load()

        used.kind = .card
        unused.kind = .card

        #expect(used.draft.problems == [.kindLocked])
        #expect(unused.draft.problems.isEmpty)
    }

    @Test
    func leavesOutFutureEntriesFromBalance() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let bank = try await setup.wallet(named: "銀行")
        let today = LocalDate(Date(), in: .current)

        let income = EntryDraft(
            type: .income,
            amount: 1000,
            date: today,
            categoryId: options.incomeCategories[0].id,
            walletId: bank.id
        )

        let future = EntryDraft(
            type: .expense,
            amount: 400,
            date: today.adding(days: 3),
            categoryId: options.expenseCategories[0].id,
            walletId: bank.id
        )

        try await setup.database.saveEntry(income, at: Date())
        try await setup.database.saveEntry(future, at: Date())
        let model = WalletEditModel(database: setup.database, editing: bank.id)

        await model.load()

        #expect(model.balance == 1000)
    }

    @Test
    func confirmsHidingWalletWithOnlyFutureEntries() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let bank = try await setup.wallet(named: "銀行")
        let today = LocalDate(Date(), in: .current)

        let future = EntryDraft(
            type: .expense,
            amount: 400,
            date: today.adding(days: 3),
            categoryId: options.expenseCategories[0].id,
            walletId: bank.id
        )

        try await setup.database.saveEntry(future, at: Date())
        let model = WalletEditModel(database: setup.database, editing: bank.id)

        await model.load()

        #expect(model.balance == 0)
        #expect(model.needsHideConfirmation)
    }

    @Test
    func locksKindWhenOnlyHiddenRecurringUsesWallet() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let cash = try await setup.wallet(named: "財布")
        let today = LocalDate(Date(), in: .current)

        let draft = RecurringDraft(
            type: .transfer,
            amount: 1000,
            categoryId: nil,
            walletId: bank.id,
            toWalletId: cash.id,
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: today.adding(days: 30)
        )

        let saved = try await setup.database.saveRecurring(
            draft,
            today: today,
            at: Date()
        )

        try await setup.database.setRecurringHidden(
            saved.id,
            isHidden: true,
            today: today,
            at: Date()
        )

        let model = WalletEditModel(database: setup.database, editing: cash.id)
        await model.load()

        model.kind = .card

        #expect(model.draft.problems == [.kindLocked])
    }

    @Test
    func locksInvestmentWithValuation() async throws {
        let setup = try await Setup()
        let today = LocalDate(Date(), in: .current)

        let adding = WalletEditModel(database: setup.database)
        adding.name = "積立"
        adding.kind = .investment
        let saved = try #require(await adding.save())

        try await setup.database.saveValuation(
            150_000,
            of: saved.id,
            on: today,
            at: Date()
        )

        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()

        model.kind = .bank

        #expect(model.draft.problems == [.valuedKindLocked])
    }

    @Test
    func locksKindRightAfterAddingValuation() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database)
        adding.name = "積立"
        adding.kind = .investment
        let saved = try #require(await adding.save())
        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()

        model.pressValuation(.digit(5))
        _ = await model.saveValuation()
        let isChanged = model.isChanged
        model.kind = .bank

        #expect(!isChanged)
        #expect(!model.canSave)
        #expect(model.draft.problems == [.valuedKindLocked])
    }

    @Test
    func unlocksKindRightAfterDeletingLastValuation() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database)
        adding.name = "積立"
        adding.kind = .investment
        let saved = try #require(await adding.save())

        try await setup.database.saveValuation(
            5,
            of: saved.id,
            on: LocalDate(Date(), in: .current),
            at: Date()
        )

        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()
        let valuation = try #require(model.valuations.first)

        await model.deleteValuation(valuation.id)
        let isChanged = model.isChanged
        model.kind = .bank

        #expect(!isChanged)
        #expect(model.canSave)
    }

    @Test
    func loadsAndEditsWallet() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let model = WalletEditModel(database: setup.database, editing: bank.id)
        await model.load()
        let loaded = model.name
        let isChanged = model.isChanged

        model.name = "ゆうちょ"
        model.press(.clear)
        model.press(.digit(1))
        model.press(.digit(2))
        model.press(.doubleZero)
        model.press(.doubleZero)
        let saved = try #require(await model.save())

        #expect(loaded == "銀行")
        #expect(!isChanged)
        #expect(!model.needsHideConfirmation)
        #expect(saved.id == bank.id)
        #expect(saved.name == "ゆうちょ")
        #expect(saved.initialBalance == 120_000)
    }

    @Test
    func savesLoanAmountAndClearsItWhenKindChanges() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database)
        adding.name = "奨学金"
        adding.kind = .loan
        adding.pressLoanAmount(.digit(3))
        adding.pressLoanAmount(.doubleZero)
        adding.pressLoanAmount(.doubleZero)
        adding.pressLoanAmount(.digit(0))
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()
        let loaded = model.loanAmount.amount
        let isChanged = model.isChanged
        let repaid = model.repaidText
        model.kind = .bank
        let changed = try #require(await model.save())

        #expect(adding.showsLoanAmount)
        #expect(saved.loanAmount == 300_000)
        #expect(loaded == 300_000)
        #expect(!isChanged)
        #expect(repaid == "¥300,000 返済済み（100%）")
        #expect(!model.showsLoanAmount)
        #expect(changed.loanAmount == nil)
    }

    @Test
    func setsInvestmentValuation() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database)
        adding.name = "つみたて"
        adding.kind = .investment
        adding.press(.digit(1))
        adding.press(.doubleZero)
        adding.press(.doubleZero)
        adding.press(.digit(0))
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()
        model.startValuation()
        let start = model.valuation.amount
        model.pressValuation(.clear)
        model.pressValuation(.digit(1))
        model.pressValuation(.digit(2))
        model.pressValuation(.doubleZero)
        model.pressValuation(.doubleZero)
        let isSaved = await model.saveValuation()

        let reloaded = WalletEditModel(
            database: setup.database,
            editing: saved.id
        )

        await reloaded.load()

        #expect(model.showsValuation)
        #expect(start == 100_000)
        #expect(isSaved)
        #expect(reloaded.balance == 120_000)
        #expect(reloaded.initialBalance == 100_000)
        #expect(reloaded.valuations.map(\.amount) == [120_000])
    }

    @Test
    func deletesValuationAndCountsFromStart() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database)
        adding.name = "つみたて"
        adding.kind = .investment
        adding.press(.digit(5))
        adding.press(.doubleZero)
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()
        model.startValuation()
        model.pressValuation(.digit(9))
        _ = await model.saveValuation()
        let valued = model.balance
        let id = try #require(model.valuations.first?.id)

        await model.deleteValuation(id)

        #expect(valued == 9)
        #expect(model.valuations.isEmpty)
        #expect(model.balance == 500)
    }

    @Test
    func asksBeforeHidingWalletWithBalance() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let options = try await setup.database.entryOptions()
        let salary = try #require(options.incomeCategories.first)
        let date = try #require(LocalDate("2026-10-01"))

        let income = EntryDraft(
            type: .income,
            amount: 5000,
            date: date,
            categoryId: salary.id,
            walletId: bank.id
        )

        try await setup.database.saveEntry(income, at: Date())

        let model = WalletEditModel(database: setup.database, editing: bank.id)
        await model.load()

        #expect(model.balance == 5000)
        #expect(model.needsHideConfirmation)
    }

    @Test
    func entrySheetSeesAddedWallet() async throws {
        let setup = try await Setup()
        let date = try #require(LocalDate("2026-10-12"))
        let entry = EntryModel(database: setup.database, date: date)
        await entry.load()

        let editor = entry.newWalletModel()
        editor.name = "楽天カード"
        editor.kind = .card
        let saved = try #require(await editor.save())
        await entry.reloadWallets()
        let wallet = try #require(entry.wallet(saved.id))

        #expect(wallet.name == "楽天カード")
        #expect(entry.balance(of: wallet) == 0)
    }

    @Test
    func refusesToHideTheLastWallet() async throws {
        let setup = try await Setup()
        let cash = try await setup.wallet(named: "財布")
        let bank = try await setup.wallet(named: "銀行")

        let bankModel = WalletEditModel(
            database: setup.database,
            editing: bank.id
        )

        let hid = await bankModel.setHidden(true)

        let cashModel = WalletEditModel(
            database: setup.database,
            editing: cash.id
        )

        let refused = await cashModel.setHidden(true)

        #expect(hid)
        #expect(!refused)
        #expect(cashModel.errorNotice.message == "最後の 1 つの口座は非表示にできません")
    }
}

extension WalletEditModelTests {
    struct Setup {
        let database: AppDatabase
    }
}

extension WalletEditModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        self.init(database: database)
    }

    func wallet(named name: String) async throws -> Wallet {
        let options = try await database.entryOptions()
        return try #require(options.wallets.first { $0.name == name })
    }
}
