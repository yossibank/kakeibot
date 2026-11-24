import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

@MainActor
struct EntryModelTests {
    @Test
    func buildsAmountFromKeys() async throws {
        let model = try await Self.newModel()

        model.state.press(.digit(1))
        model.state.press(.digit(2))
        model.state.press(.doubleZero)

        #expect(model.output.amount == 1200)

        model.state.press(.delete)

        #expect(model.output.amount == 120)
    }

    @Test
    func capsAmountAtNineDigits() async throws {
        let model = try await Self.newModel()

        for _ in 0..<10 {
            model.state.press(.digit(9))
        }

        #expect(model.output.amount == 999_999_999)
    }

    @Test
    func picksFirstCategoryOfSelectedType() async throws {
        let model = try await Self.newModel()

        model.select(.income)

        #expect(model.state.category.id == model.input.options?.incomeCategories.first?.id)
    }

    @Test
    func savesNewEntry() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        model.state.press(.digit(5))
        model.state.press(.doubleZero)
        model.state.memo = "ランチ"

        let saved = await model.save()
        let entries = try setup.database.snapshot().entries

        #expect(saved?.entry.amount == 500)
        #expect(entries.map(\.amount) == [500])
        #expect(entries.map(\.memo) == ["ランチ"])
    }

    @Test
    func savesOnceWhenSaveIsTappedTwice() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        model.state.press(.digit(5))

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

        #expect(model.output.canSave == false)
        #expect(saved == nil)
        #expect(model.state.errorNotice.message == "金額を入れてください")
    }

    @Test
    func editsExistingEntry() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(
            parts: .system(setup.database),
            editing: entry.id,
            date: setup.date
        )
        await model.load()

        model.state.press(.delete)
        let saved = await model.save()
        let stored = try await setup.database.entry(entry.id)

        #expect(saved?.entry.id == entry.id)
        #expect(stored?.amount == 98)
        #expect(stored?.createdAt == entry.createdAt)
    }

    @Test
    func recordsEditedEntryAgainAsNewEntry() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(
            parts: .system(setup.database),
            editing: entry.id,
            date: setup.date
        )
        await model.load()
        model.state.memo = "ランチ"

        await model.recordAgain()
        let saved = await model.save()
        let entries = try setup.database.snapshot().entries
        let stored = try await setup.database.entry(entry.id)

        #expect(!model.output.isEditing)
        #expect(model.state.errorNotice.message == "同じ内容で新しい記録にしました")
        #expect(saved?.entry.id != entry.id)
        #expect(saved?.entry.amount == 980)
        #expect(saved?.entry.memo == "ランチ")
        #expect(saved?.entry.categoryId == entry.categoryId)
        #expect(saved?.entry.date == LocalDate(Date(), in: .current))
        #expect(entries.count == 2)
        #expect(stored?.memo == entry.memo)
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
            model.state.press(key)
        }

        let expression = model.output.expressionText
        model.state.press(.equals)
        let settled = model.output.expressionText
        model.state.press(.tax(.standard))

        #expect(expression == "1,200 ＋ 8")
        #expect(settled == nil)
        #expect(model.output.expressionText == "1,208 の税込み 10%")
        #expect(model.output.amount == 1328)
    }

    @Test
    func groupsWalletsByKind() async throws {
        let model = try await Self.newModel()

        let sections = model.output.walletSections

        #expect(sections.map(\.kind) == [.cash, .bank])
        #expect(sections.map { $0.wallets.map(\.name) } == [["財布"], ["銀行"]])
    }

    @Test
    func splitsCategoriesAddAndEditIntoPages() async throws {
        let model = try await Self.newModel()

        let expensePages = model.output.categoryPages
        model.select(.income)
        let incomePages = model.output.categoryPages

        #expect(expensePages.map(\.count) == [14])
        #expect(expensePages[0].suffix(2) == [.add, .edit])
        #expect(incomePages.map(\.count) == [5])
        #expect(incomePages[0].suffix(2) == [.add, .edit])
    }

    @Test
    func remembersCategoryForEachType() async throws {
        let model = try await Self.newModel()
        let expense = model.output.categories
        let transit = try #require(expense.first { $0.name == "交通" })
        model.state.setCategory(transit.id)

        model.select(.income)
        let incomeFirst = model.output.selectedCategory?.name
        let income = model.output.categories
        let bonus = try #require(income.first { $0.name == "臨時収入" })
        model.state.setCategory(bonus.id)

        model.select(.expense)
        let expenseBack = model.output.selectedCategory?.name

        model.select(.income)

        #expect(incomeFirst == "給料")
        #expect(expenseBack == "交通")
        #expect(model.output.selectedCategory?.name == "臨時収入")
    }

    @Test
    func tracksChangesAfterLoading() async throws {
        let model = try await Self.newModel()
        let loaded = model.output.isChanged

        model.state.press(.digit(5))
        let typed = model.output.isChanged

        model.state.press(.clear)
        let cleared = model.output.isChanged

        model.state.memo = "ランチ"

        #expect(!loaded)
        #expect(typed)
        #expect(!cleared)
        #expect(model.output.isChanged)
    }

    @Test
    func ignoresTypeSwitchOnUntouchedNewEntry() async throws {
        let model = try await Self.newModel()

        model.select(.income)
        let income = model.output.isChanged

        model.select(.transfer)
        let transfer = model.output.isChanged

        model.state.press(.digit(5))
        model.select(.expense)

        #expect(!income)
        #expect(!transfer)
        #expect(model.output.isChanged)
    }

    @Test
    func ignoresCancelledLoad() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)

        let task = Task {
            await model.load()
        }

        task.cancel()
        await task.value

        #expect(model.state.errorNotice.message == nil)
        #expect(model.state.errorNotice.count == 0)
    }

    @Test
    func hidesSelectedCategoryAndSelectsItAgainOnUndo() async throws {
        let model = try await Self.newModel()
        let food = try #require(model.output.selectedCategory)

        let hidden = try #require(await model.hideCategory(food))
        let next = model.output.selectedCategory?.name

        await model.showCategory(hidden)

        #expect(hidden.wasSelected)
        #expect(next == "日用品")
        #expect(model.output.categories.contains { $0.id == food.id })
        #expect(model.output.selectedCategory?.id == food.id)
    }

    @Test
    func keepsSelectionWhenUndoingHiddenOtherCategory() async throws {
        let model = try await Self.newModel()
        let food = try #require(model.output.selectedCategory)
        let other = try #require(model.output.categories.last)

        let hidden = try #require(await model.hideCategory(other))
        await model.showCategory(hidden)

        #expect(!hidden.wasSelected)
        #expect(model.output.categories.contains { $0.id == other.id })
        #expect(model.output.selectedCategory?.id == food.id)
    }

    @Test
    func selectsAddedCategory() async throws {
        let model = try await Self.newModel()
        model.select(.income)
        let editor = model.newCategoryModel()
        editor.state.name = "配当"
        editor.state.icon.glyph = .invest

        let saved = try #require(await editor.save())
        await model.reloadCategories(selecting: saved.id)

        #expect(editor.input.kind == .income)
        #expect(model.state.category.id == saved.id)
        #expect(model.output.categories.last?.name == "配当")
    }

    @Test
    func labelsSaveButtonByState() async throws {
        let model = try await Self.newModel()

        let empty = model.output.saveTitle
        model.state.press(.digit(9))
        model.state.press(.digit(8))
        model.state.press(.digit(0))
        let recorded = model.output.saveTitle

        #expect(empty == "金額を入れてください")
        #expect(recorded == "記録する")
    }

    @Test
    func deletesExistingEntry() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(
            parts: .system(setup.database),
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
    func startsNextEntryKeepingChoices() async throws {
        let model = try await Self.newModel()
        model.state.press(.digit(5))
        model.state.memo = "ランチ"
        let category = model.state.category.id
        let wallet = model.state.payment.walletId

        _ = await model.save()
        await model.startNext()

        #expect(model.output.amount == 0)
        #expect(model.state.memo.isEmpty)
        #expect(model.state.category.id == category)
        #expect(model.state.payment.walletId == wallet)
        #expect(!model.output.isChanged)
    }
}

extension EntryModelTests {
    static func newModel() async throws -> EntryModel {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)

        await model.load()

        return model
    }
}
