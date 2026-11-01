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
    func savesOnceWhenSaveIsTappedTwice() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.press(.digit(5))

        async let first = model.save()
        async let second = model.save()
        let changes = await [first, second].compactMap(\.self)
        let entries = try setup.database.snapshot().entries

        #expect(changes.count == 1)
        #expect(entries.count == 1)
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
    func opensKeypadOnlyForNewEntries() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)

        let new = EntryModel(database: setup.database, date: setup.date)
        let edit = EntryModel(database: setup.database, editing: entry.id, date: setup.date)

        #expect(new.opensKeypad)
        #expect(!edit.opensKeypad)
    }

    @Test
    func editsExistingEntry() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)
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
    func splitsCategoriesAddAndEditIntoPages() async throws {
        let model = try await Self.newModel()

        let expensePages = model.categoryPages
        model.select(.income)
        let incomePages = model.categoryPages

        #expect(expensePages.map(\.count) == [14])
        #expect(expensePages[0].suffix(2) == [.add, .edit])
        #expect(incomePages.map(\.count) == [5])
        #expect(incomePages[0].suffix(2) == [.add, .edit])
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
    func hidesSelectedCategoryAndSelectsItAgainOnUndo() async throws {
        let model = try await Self.newModel()
        let food = try #require(model.selectedCategory)

        let hidden = try #require(await model.hideCategory(food))
        let next = model.selectedCategory?.name

        await model.showCategory(hidden)

        #expect(hidden.wasSelected)
        #expect(next == "日用品")
        #expect(model.categories.contains { $0.id == food.id })
        #expect(model.selectedCategory?.id == food.id)
    }

    @Test
    func keepsSelectionWhenUndoingHiddenOtherCategory() async throws {
        let model = try await Self.newModel()
        let food = try #require(model.selectedCategory)
        let other = try #require(model.categories.last)

        let hidden = try #require(await model.hideCategory(other))
        await model.showCategory(hidden)

        #expect(!hidden.wasSelected)
        #expect(model.categories.contains { $0.id == other.id })
        #expect(model.selectedCategory?.id == food.id)
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
        #expect(model.saveSubject == "食費")
    }

    @Test
    func describesSaveDetail() async throws {
        let model = try await Self.newModel()
        let today = model.date

        let empty = model.saveDetail(today: today)
        model.press(.digit(5))
        let recorded = model.saveDetail(today: today)
        model.date = today.adding(days: -2)
        let earlier = model.saveDetail(today: today)

        #expect(empty == nil)
        #expect(recorded == "今日・財布から")
        #expect(earlier == "10/10・財布から")
    }

    @Test
    func showsMonthTotalOfCategoryWithoutBudget() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let wallet = try #require(options.wallets.first?.id)
        let categories = options.expenseCategories
        let today = LocalDate(Date(), in: .current)
        try await setup.saveEntry(category: categories[0].id, wallet: wallet, at: 1)
        try await setup.saveEntry(category: categories[0].id, wallet: wallet, at: 2)
        try await setup.saveEntry(category: categories[1].id, wallet: wallet, at: 3)
        let model = EntryModel(database: setup.database, date: today)
        await model.load()

        let empty = model.monthTotalText
        model.press(.digit(3))
        model.press(.doubleZero)

        #expect(empty == "今月の食費 ¥1,000")
        #expect(model.monthTotalText == "今月の食費 ¥1,000 → ¥1,300")
    }

    @Test
    func showsMonthTotalOfTypeWithoutCategory() async throws {
        let model = try await Self.newModel()
        model.date = LocalDate(Date(), in: .current)
        model.categoryId = nil
        model.press(.digit(2))

        #expect(model.monthTotalText == "今月の支出 ¥0 → ¥2")

        model.select(.income)
        model.categoryId = nil

        #expect(model.monthTotalText == "今月の収入 ¥0 → ¥2")
    }

    @Test
    func replacesEditedAmountInMonthTotal() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let wallet = try #require(options.wallets.first?.id)
        try await setup.saveEntry(category: options.expenseCategories[0].id, wallet: wallet, at: 1)
        let entry = try #require(try setup.database.snapshot().entries.first)
        let model = EntryModel(database: setup.database, editing: entry.id, date: entry.date)

        await model.load()
        model.press(.delete)
        model.press(.delete)
        model.press(.delete)
        model.press(.digit(7))
        model.press(.doubleZero)

        #expect(model.monthTotalText == "今月の食費 ¥500 → ¥700")
    }

    @Test
    func removesEntryMovedOutOfMonthFromTotal() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let wallet = try #require(options.wallets.first?.id)
        try await setup.saveEntry(category: options.expenseCategories[0].id, wallet: wallet, at: 1)
        let entry = try #require(try setup.database.snapshot().entries.first)
        let model = EntryModel(database: setup.database, editing: entry.id, date: entry.date)

        await model.load()
        model.date = entry.date.adding(days: -62)

        #expect(model.monthTotalText == "今月の食費 ¥500 → ¥0")
    }

    @Test
    func deletesExistingEntry() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)
        await model.load()

        let deleted = await model.delete()
        let stored = try await setup.database.entry(entry.id)

        #expect(deleted?.entry == entry)
        #expect(stored == nil)
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
}

private extension EntryModelTests {
    static func newModel() async throws -> EntryModel {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)

        await model.load()

        return model
    }
}
