import Core
import Features
import Foundation
import Store
import Testing

extension TransferEntryTests {
    @Test
    func keepsHiddenWalletsWhenEditing() async throws {
        let setup = try await Setup()
        let billMonth = try #require(YearMonth(year: 2026, month: 11))

        let options = try await setup.database.entryOptions()

        let draft = EntryDraft(
            type: .expense,
            amount: 800,
            date: setup.date,
            categoryId: options.expenseCategories[0].id,
            walletId: setup.cash,
            billMonth: billMonth
        )

        let entry = try await setup.database.saveEntry(draft, at: Date())
        try await setup.database.setWalletHidden(setup.cash, isHidden: true, at: Date())
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)

        await model.load()
        await model.reloadWallets()

        #expect(model.walletId == setup.cash)
        #expect(model.billMonth == entry.billMonth)
        #expect(model.wallet(setup.cash) != nil)
        #expect(model.wallet(setup.bank) != nil)
    }

    @Test
    func keepsHiddenTransferWalletsWhenEditing() async throws {
        let setup = try await Setup()
        try await setup.saveTransfer(3000, from: setup.cash, to: setup.bank, at: 1)
        let transfer = try #require(setup.database.snapshot().entries.first)
        try await setup.database.setWalletHidden(setup.bank, isHidden: true, at: Date())
        let model = EntryModel(database: setup.database, editing: transfer.id, date: setup.date)

        await model.load()
        await model.reloadWallets()

        #expect(model.walletId == setup.cash)
        #expect(model.toWalletId == setup.bank)
        #expect(model.wallet(setup.bank) != nil)
    }

    @Test
    func keepsHiddenCategoryWhenEditing() async throws {
        let setup = try await Setup()

        let draft = EntryDraft(
            type: .income,
            amount: 3000,
            date: setup.date,
            categoryId: setup.salary,
            walletId: setup.cash
        )

        let entry = try await setup.database.saveEntry(draft, at: Date())
        try await setup.database.setCategoryHidden(setup.salary, isHidden: true, at: Date())
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)

        await model.load()
        await model.reloadCategories()

        #expect(model.categoryId == setup.salary)
        #expect(model.selectedCategory?.id == setup.salary)
    }

    @Test
    func reselectsDeletedWalletWhenEditing() async throws {
        let setup = try await Setup()

        let options = try await setup.database.entryOptions()

        let draft = EntryDraft(
            type: .expense,
            amount: 800,
            date: setup.date,
            categoryId: options.expenseCategories[0].id,
            walletId: setup.cash
        )

        let entry = try await setup.database.saveEntry(draft, at: Date())
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)

        await model.load()
        model.walletId = setup.bank
        _ = try await setup.database.deleteWallet(setup.bank, at: Date())
        await model.reloadWallets()

        #expect(model.walletId != setup.bank)
        #expect(model.walletId != nil)
    }

    @Test
    func reselectsDeletedCategoryWhenEditing() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let other = options.incomeCategories[1].id

        let draft = EntryDraft(
            type: .income,
            amount: 3000,
            date: setup.date,
            categoryId: setup.salary,
            walletId: setup.cash
        )

        let entry = try await setup.database.saveEntry(draft, at: Date())
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)

        await model.load()
        model.categoryId = other
        _ = try await setup.database.deleteCategory(other, at: Date())
        await model.reloadCategories()

        #expect(model.categoryId != other)
        #expect(model.categoryId != nil)
    }

    @Test
    func restoresHiddenCategoryAfterSwitchingType() async throws {
        let setup = try await Setup()

        let draft = EntryDraft(
            type: .income,
            amount: 3000,
            date: setup.date,
            categoryId: setup.salary,
            walletId: setup.cash
        )

        let entry = try await setup.database.saveEntry(draft, at: Date())
        try await setup.database.setCategoryHidden(setup.salary, isHidden: true, at: Date())
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)

        await model.load()
        model.select(.expense)
        model.select(.income)

        #expect(model.categoryId == setup.salary)
    }
}
