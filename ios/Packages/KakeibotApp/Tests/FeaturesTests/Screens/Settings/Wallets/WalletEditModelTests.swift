import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct WalletEditModelTests {
    @Test
    func addsCardWithNegativeBalance() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))
        model.state.name = "楽天カード"
        model.state.setKind(.card)
        model.state.press(.digit(3))
        model.state.press(.digit(8))
        model.state.press(.doubleZero)
        model.state.press(.digit(0))

        let saved = try #require(await model.save())
        let list = try await setup.database.entryList()
        let icon = try #require(list.icons[saved.iconId])

        #expect(model.state.calculator.amount == 38000)
        #expect(saved.initialBalance == -38000)
        #expect(saved.kind == .card)
        #expect(icon.glyph == .card)
    }

    @Test
    func namesWhatIsMissingOnSaveButton() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let model = WalletEditModel(parts: .system(setup.database))
        let editing = WalletEditModel(parts: .system(setup.database), editing: bank.id)
        await editing.load()

        let empty = model.saveTitle
        model.state.name = "楽天カード"
        let named = model.saveTitle
        model.state.icon.markKind = .emoji
        let noMark = model.saveTitle

        #expect(empty == "名前を入れてください")
        #expect(named == "追加する")
        #expect(noMark == "アイコンを選んでください")
        #expect(editing.saveTitle == "変更を保存")
    }

    @Test
    func tracksChangesFromStart() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))
        let start = model.isChanged

        model.state.name = "楽天カード"
        let named = model.isChanged

        model.state.name = ""
        let cleared = model.isChanged

        model.state.setKind(.bank)
        let kindChanged = model.isChanged

        #expect(!start)
        #expect(named)
        #expect(!cleared)
        #expect(kindChanged)
    }

    @Test
    func keepsChosenGlyphWhenKindChanges() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))

        model.state.setKind(.bank)
        let followed = model.state.icon.glyph
        model.state.icon.glyph = .coin
        model.state.setKind(.card)

        #expect(followed == .bank)
        #expect(model.state.icon.glyph == .coin)
    }

    @Test
    func followsSignWhenKindChanges() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))

        model.state.setKind(.card)
        let card = model.state.isNegative
        model.state.setKind(.bank)
        let bank = model.state.isNegative
        model.state.isNegative = true
        model.state.setKind(.cash)

        #expect(card)
        #expect(!bank)
        #expect(model.state.isNegative)
    }

    @Test
    func switchesSignWithKeypadOnlyBeforeAmount() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))

        model.state.press(.operation(.subtract))
        let minus = model.state.isNegative
        model.state.press(.operation(.add))
        let plus = model.state.isNegative
        model.state.press(.operation(.subtract))
        model.state.press(.digit(5))
        model.state.press(.doubleZero)
        model.state.press(.operation(.add))
        model.state.press(.digit(3))
        model.state.press(.doubleZero)
        model.state.press(.operation(.subtract))
        model.state.press(.digit(1))
        model.state.press(.doubleZero)

        #expect(minus)
        #expect(!plus)
        #expect(model.state.isNegative)
        #expect(model.output.initialBalance == -700)
        #expect(model.output.balanceText == "−¥700")
    }

    @Test
    func startsDebtAsMinusAndKeepsChosenSign() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))

        model.state.setKind(.loan)
        let loan = model.state.isNegative
        model.state.isNegative = false
        model.state.setKind(.card)
        let overpaid = model.state.isNegative

        #expect(loan)
        #expect(!overpaid)
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
        let used = WalletEditModel(parts: .system(setup.database), editing: bank.id)
        let unused = WalletEditModel(parts: .system(setup.database), editing: cash.id)
        await used.load()
        await unused.load()

        used.state.setKind(.card)
        unused.state.setKind(.card)

        #expect(used.output.draft.problems == [.kindLocked])
        #expect(unused.output.draft.problems.isEmpty)
        #expect(used.input.hasEntries)
        #expect(!unused.input.hasEntries)
    }

    @Test
    func leavesOutFutureEntriesFromBalance() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let bank = try await setup.wallet(named: "銀行")
        let today = LocalDate(Date(), in: .current)
        let futureDate = today.adding(days: 3)

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
            date: futureDate,
            categoryId: options.expenseCategories[0].id,
            walletId: bank.id
        )

        try await setup.database.saveEntry(income, at: Date())
        try await setup.database.saveEntry(future, at: Date())
        let model = WalletEditModel(parts: .system(setup.database), editing: bank.id)

        await model.load()

        #expect(model.input.balance == 1000)
    }

    @Test
    func confirmsHidingWalletWithOnlyFutureEntries() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let bank = try await setup.wallet(named: "銀行")
        let today = LocalDate(Date(), in: .current)
        let futureDate = today.adding(days: 3)

        let future = EntryDraft(
            type: .expense,
            amount: 400,
            date: futureDate,
            categoryId: options.expenseCategories[0].id,
            walletId: bank.id
        )

        try await setup.database.saveEntry(future, at: Date())
        let model = WalletEditModel(parts: .system(setup.database), editing: bank.id)

        await model.load()

        #expect(model.input.balance == 0)
        #expect(model.output.needsHideConfirmation)
    }

    @Test
    func locksKindWhenOnlyHiddenRecurringUsesWallet() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let cash = try await setup.wallet(named: "財布")
        let today = LocalDate(Date(), in: .current)
        let start = today.adding(days: 30)

        let draft = RecurringDraft(
            type: .transfer,
            amount: 1000,
            categoryId: nil,
            walletId: bank.id,
            toWalletId: cash.id,
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: start
        )

        let saved = try await setup.database.saveRecurring(draft, today: today, at: Date())

        try await setup.database.setRecurringHidden(
            saved.id,
            isHidden: true,
            today: today,
            at: Date()
        )

        let model = WalletEditModel(parts: .system(setup.database), editing: cash.id)
        await model.load()

        model.state.setKind(.card)

        #expect(model.output.draft.problems == [.kindLocked])
        #expect(!model.input.hasEntries)
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
