import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct EntryModelTests {
    @Test
    func buildsAmountFromKeys() async throws {
        let model = try await Self.newModel()

        model.press(.digit(1))
        model.press(.digit(2))
        model.press(.doubleZero)

        #expect(model.amount == 1200)

        model.press(.delete)

        #expect(model.amount == 120)
    }

    @Test
    func opensKeypadFirstWhenChosen() async throws {
        let setup = try await Setup()
        let initial = EntryModel(database: setup.database, date: setup.date)
        await initial.load()
        try await setup.database.setSetting(.entryStartsWithAmount, to: true)
        let model = EntryModel(database: setup.database, date: setup.date)

        await model.load()

        #expect(!initial.opensKeypadFirst)
        #expect(model.opensKeypadFirst)
    }

    @Test
    func capsAmountAtNineDigits() async throws {
        let model = try await Self.newModel()

        for _ in 0..<10 {
            model.press(.digit(9))
        }

        #expect(model.amount == 999_999_999)
    }

    @Test
    func picksFirstCategoryOfSelectedType() async throws {
        let model = try await Self.newModel()

        model.select(.income)

        #expect(model.categoryId == model.options?.incomeCategories.first?.id)
    }

    @Test
    func savesNewEntry() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.press(.digit(5))
        model.press(.doubleZero)
        model.memo = "ランチ"

        let saved = await model.save()
        let entries = try setup.database.snapshot().entries

        #expect(saved?.entry.amount == 500)
        #expect(entries.map(\.amount) == [500])
        #expect(entries.map(\.memo) == ["ランチ"])
    }

    @Test
    func refusesZeroAmount() async throws {
        let model = try await Self.newModel()

        let saved = await model.save()

        #expect(model.canSave == false)
        #expect(saved == nil)
        #expect(model.errorNotice.message == "金額を入れてください")
    }

    @Test
    func editsExistingEntry() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)

        let model = EntryModel(
            database: setup.database,
            editing: entry.id,
            date: setup.date
        )

        await model.load()

        model.press(.delete)
        let saved = await model.save()
        let stored = try await setup.database.entry(entry.id)

        #expect(saved?.entry.id == entry.id)
        #expect(stored?.amount == 98)
        #expect(stored?.createdAt == entry.createdAt)
    }

    @Test
    func describesExpressionAndTax() async throws {
        let model = try await Self.newModel()

        for key: AmountCalculator.Key in [
            .digit(1),
            .digit(2),
            .doubleZero,
            .operation(.add),
            .digit(8)
        ] {
            model.press(key)
        }

        let expression = model.expressionText
        model.press(.equals)
        let settled = model.expressionText
        model.press(.tax(.standard))

        #expect(expression == "1,200 ＋ 8")
        #expect(settled == nil)
        #expect(model.expressionText == "1,208 の税込み 10%")
        #expect(model.amount == 1328)
    }

    @Test
    func groupsWalletsByKind() async throws {
        let model = try await Self.newModel()

        let sections = model.walletSections

        #expect(sections.map(\.kind) == [.cash, .bank])
        #expect(sections.map { $0.wallets.map(\.name) } == [["財布"], ["銀行"]])
    }

    @Test
    func splitsCategoriesAndAddIntoPages() async throws {
        let model = try await Self.newModel()

        let expensePages = model.categoryPages
        model.select(.income)
        let incomePages = model.categoryPages

        #expect(expensePages.map(\.count) == [13])
        #expect(expensePages[0].last == .add)
        #expect(incomePages.map(\.count) == [4])
        #expect(incomePages[0].last == .add)
    }

    @Test
    func remembersCategoryForEachType() async throws {
        let model = try await Self.newModel()
        let expense = model.categories
        let transit = try #require(expense.first { $0.name == "交通" })
        model.categoryId = transit.id

        model.select(.income)
        let incomeFirst = model.selectedCategory?.name
        let income = model.categories
        let bonus = try #require(income.first { $0.name == "臨時収入" })
        model.categoryId = bonus.id

        model.select(.expense)
        let expenseBack = model.selectedCategory?.name

        model.select(.income)

        #expect(incomeFirst == "給料")
        #expect(expenseBack == "交通")
        #expect(model.selectedCategory?.name == "臨時収入")
    }

    @Test
    func tracksChangesAfterLoading() async throws {
        let model = try await Self.newModel()
        let loaded = model.isChanged

        model.press(.digit(5))
        let typed = model.isChanged

        model.press(.clear)
        let cleared = model.isChanged

        model.memo = "ランチ"

        #expect(!loaded)
        #expect(typed)
        #expect(!cleared)
        #expect(model.isChanged)
    }

    @Test
    func ignoresCancelledLoad() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)

        let task = Task {
            await model.load()
        }

        task.cancel()
        await task.value

        #expect(model.errorNotice.message == nil)
        #expect(model.errorNotice.count == 0)
    }

    @Test
    func hidesSelectedCategoryAndSelectsNext() async throws {
        let model = try await Self.newModel()
        let food = try #require(model.selectedCategory)

        await model.hideCategory(food)

        #expect(!model.categories.contains(food))
        #expect(model.selectedCategory?.name == "日用品")
    }

    @Test
    func selectsAddedCategory() async throws {
        let model = try await Self.newModel()
        model.select(.income)
        let editor = model.newCategoryModel()
        editor.name = "配当"
        editor.icon.glyph = .invest

        let saved = try #require(await editor.save())
        await model.reloadCategories(selecting: saved.id)

        #expect(editor.kind == .income)
        #expect(model.categoryId == saved.id)
        #expect(model.categories.last?.name == "配当")
    }

    @Test
    func namesSaveButtonByState() async throws {
        let model = try await Self.newModel()

        let empty = model.saveTitle
        model.press(.digit(9))
        model.press(.digit(8))
        model.press(.digit(0))

        #expect(empty == "金額を入れてください")
        #expect(model.saveTitle == "¥980 を記録する")
    }

    @Test(arguments: [
        ("2026-10-12", "今日 10/12（月）"),
        ("2026-10-11", "昨日 10/11（日）"),
        ("2026-10-05", "10/5（月）"),
        ("2025-12-31", "2025/12/31（水）")
    ])
    func describesDate(text: String, expected: String) throws {
        let today = try #require(LocalDate("2026-10-12"))
        let date = try #require(LocalDate(text))

        let description = EntryModel.dateText(for: date, today: today)

        #expect(description == expected)
    }

    @Test
    func deletesExistingEntry() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)

        let model = EntryModel(
            database: setup.database,
            editing: entry.id,
            date: setup.date
        )

        await model.load()

        let deleted = await model.delete()
        let stored = try await setup.database.entry(entry.id)

        #expect(deleted?.entry == entry)
        #expect(stored == nil)
    }

    @Test
    func movesCardUsageToLaterBill() async throws {
        let setup = try await Setup()
        let card = try await setup.cardWithBill()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.press(.digit(5))
        model.walletId = card.id

        let dates = model.billChoices.map(\.date.description)
        let later = try #require(model.billChoices.last?.date)
        model.selectBill(later)
        let name = model.walletName
        let change = await model.save()

        #expect(dates == ["2026-11-27", "2026-12-27", "2027-01-27"])
        #expect(name == "カード → 1/27")
        #expect(change?.entry.billMonth == later.yearMonth)

        model.date = try #require(LocalDate("2026-10-13"))

        #expect(model.billMonth == nil)
    }

    @Test
    func followsLastWalletOfCategory() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let categories = options.expenseCategories
        let wallets = options.wallets
        try await setup.saveEntry(category: categories[0].id, wallet: wallets[1].id, at: 1)
        try await setup.saveEntry(category: categories[1].id, wallet: wallets[0].id, at: 2)
        let model = EntryModel(database: setup.database, date: setup.date)

        await model.load()
        let first = model.walletId
        model.categoryId = categories[1].id
        let second = model.walletId

        #expect(first == wallets[1].id)
        #expect(second == wallets[0].id)
    }

    @Test
    func keepsChosenWallet() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let categories = options.expenseCategories
        let wallets = options.wallets
        try await setup.saveEntry(category: categories[1].id, wallet: wallets[0].id, at: 1)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.categoryId = categories[1].id
        model.walletId = wallets[1].id
        model.categoryId = categories[2].id

        #expect(model.walletId == wallets[1].id)
    }

    @Test
    func startsNextEntryKeepingChoices() async throws {
        let model = try await Self.newModel()
        model.press(.digit(5))
        model.memo = "ランチ"
        let category = model.categoryId
        let wallet = model.walletId

        _ = await model.save()
        await model.startNext()

        #expect(model.amount == 0)
        #expect(model.memo.isEmpty)
        #expect(model.categoryId == category)
        #expect(model.walletId == wallet)
        #expect(!model.isChanged)
    }

    @Test
    func ordersCategoriesByUseWhenChosen() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let third = options.expenseCategories[2]
        let wallet = options.wallets[0]
        try await setup.saveEntry(category: third.id, wallet: wallet.id, at: 1)
        let manual = EntryModel(database: setup.database, date: setup.date)
        await manual.load()
        try await setup.database.setSetting(.categoriesByUse, to: true)
        let model = EntryModel(database: setup.database, date: setup.date)

        await model.load()

        #expect(manual.categoryId == options.expenseCategories[0].id)
        #expect(model.categoryId == third.id)
        #expect(model.categoryPages.first?.first?.categoryId == third.id)
    }
}

extension EntryModelTests {
    struct Setup {
        let database: AppDatabase
        let date: LocalDate
    }
}

extension EntryModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let date = try #require(LocalDate("2026-10-12"))
        self.init(database: database, date: date)
    }

    func saveEntry(amount: Int) async throws -> Entry {
        let options = try await database.entryOptions()
        let categoryId = options.expenseCategories.first?.id
        let walletId = try #require(options.wallets.first?.id)

        let draft = EntryDraft(
            type: .expense,
            amount: amount,
            date: date,
            categoryId: categoryId,
            walletId: walletId
        )

        let now = Date(timeIntervalSince1970: 1_791_000_000)
        return try await database.saveEntry(draft, at: now)
    }

    func saveEntry(
        category categoryId: EntryCategory.ID,
        wallet walletId: Wallet.ID,
        at seconds: TimeInterval
    ) async throws {
        let draft = EntryDraft(
            type: .expense,
            amount: 500,
            date: LocalDate(Date(), in: .current),
            categoryId: categoryId,
            walletId: walletId
        )

        let createdAt = Date(timeIntervalSince1970: seconds)

        try await database.saveEntry(draft, at: createdAt)
    }

    func cardWithBill() async throws -> Wallet {
        let options = try await database.entryOptions()
        let bank = options.wallets.first { $0.kind == .bank }

        let card = try await database.saveWallet(
            WalletDraft(
                kind: .card,
                name: "カード",
                mark: .glyph(.card),
                color: "#4A6FA5",
                initialBalance: 0
            ),
            at: Date()
        )

        _ = try await database.saveRecurring(
            RecurringDraft(
                type: .transfer,
                amount: 0,
                categoryId: nil,
                walletId: bank?.id,
                toWalletId: card.id,
                frequency: .monthly,
                month: 1,
                day: 27,
                closingDay: 31,
                startDate: date
            ),
            today: date,
            at: Date()
        )

        return card
    }
}

private extension EntryModelTests {
    static func newModel() async throws -> EntryModel {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        return model
    }
}
