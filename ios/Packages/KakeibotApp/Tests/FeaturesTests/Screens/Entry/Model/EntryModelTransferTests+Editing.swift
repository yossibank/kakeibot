import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

extension EntryModelTransferTests {
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
        try await setup.database.setHidden(setup.cash, isHidden: true, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: entry.id,
            date: setup.date
        )

        await model.load()
        await model.reloadWallets()

        #expect(model.state.payment.walletId == setup.cash)
        #expect(model.state.payment.billMonth == entry.billMonth)
        #expect(model.output.wallet(setup.cash) != nil)
        #expect(model.output.wallet(setup.bank) != nil)
    }

    @Test
    func keepsHiddenTransferWalletsWhenEditing() async throws {
        let setup = try await Setup()
        try await setup.saveTransfer(3000, from: setup.cash, to: setup.bank, at: 1)
        let transfer = try #require(setup.database.snapshot().entries.first)
        try await setup.database.setHidden(setup.bank, isHidden: true, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: transfer.id,
            date: setup.date
        )

        await model.load()
        await model.reloadWallets()

        #expect(model.state.payment.walletId == setup.cash)
        #expect(model.state.payment.toWalletId == setup.bank)
        #expect(model.output.wallet(setup.bank) != nil)
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
        try await setup.database.setHidden(setup.salary, isHidden: true, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: entry.id,
            date: setup.date
        )

        await model.load()
        await model.reloadCategories()

        #expect(model.state.category.id == setup.salary)
        #expect(model.output.selectedCategory?.id == setup.salary)
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
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: entry.id,
            date: setup.date
        )

        await model.load()
        model.setWallet(setup.bank)
        _ = try await setup.database.deleteWallet(setup.bank, at: Date())
        await model.reloadWallets()

        #expect(model.state.payment.walletId != setup.bank)
        #expect(model.state.payment.walletId != nil)
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
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: entry.id,
            date: setup.date
        )

        await model.load()
        model.state.setCategory(other)
        _ = try await setup.database.deleteCategory(other, at: Date())
        await model.reloadCategories()

        #expect(model.state.category.id != other)
        #expect(model.state.category.id != nil)
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
        try await setup.database.setHidden(setup.salary, isHidden: true, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: entry.id,
            date: setup.date
        )

        await model.load()
        model.select(.expense)
        model.select(.income)

        #expect(model.state.category.id == setup.salary)
    }
}
