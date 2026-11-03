import Core
import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
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
}
