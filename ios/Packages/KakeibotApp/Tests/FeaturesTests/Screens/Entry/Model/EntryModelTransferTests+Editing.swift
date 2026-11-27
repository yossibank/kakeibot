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
            parts: .system(setup.database),
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
            parts: .system(setup.database),
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
            parts: .system(setup.database),
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
            parts: .system(setup.database),
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
            parts: .system(setup.database),
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
            parts: .system(setup.database),
            editing: entry.id,
            date: setup.date
        )

        await model.load()
        model.select(.expense)
        model.select(.income)

        #expect(model.state.category.id == setup.salary)
    }

    @Test
    func fitsCategoryToSharedWalletWhenEditing() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let own = options.expenseCategories[0]
        try await setup.database.startSharing(setup.bank)

        let draft = EntryDraft(
            type: .expense,
            amount: 800,
            date: setup.date,
            categoryId: own.id,
            walletId: setup.bank
        )

        let entry = try await setup.database.saveEntry(draft, at: Date())
        try await setup.database.setCategory(of: entry.id, to: own.id)
        let model = EntryModel(
            parts: .system(setup.database),
            editing: entry.id,
            date: setup.date
        )

        await model.load()

        #expect(entry.categoryId != own.id)
        #expect(model.state.payment.walletId == setup.bank)
        #expect(model.state.category.id == entry.categoryId)
        #expect(model.output.selectedCategory?.name == own.name)
        #expect(model.output.selectedCategory?.walletId == setup.bank)
        #expect(!model.output.isChanged)
    }

    @Test
    func reportsMissingEntryWhenLoading() async throws {
        let setup = try await Setup()
        let model = EntryModel(
            parts: .system(setup.database),
            editing: Entry.ID(),
            date: setup.date
        )

        await model.load()
        let change = await model.save()

        #expect(model.state.notices.error.message == "記録が見つかりませんでした")
        #expect(model.output.isEditing)
        #expect(model.state.payment.walletId == nil)
        #expect(model.state.category.id == nil)
        #expect(!model.output.isChanged)
        #expect(change == nil)
    }

    @Test
    func deletesNothingWhenEntryIsMissing() async throws {
        let setup = try await Setup()
        let model = EntryModel(
            parts: .system(setup.database),
            editing: Entry.ID(),
            date: setup.date
        )

        await model.load()
        let change = await model.delete()

        #expect(change == nil)
        #expect(model.state.notices.error.message == "記録が見つかりませんでした")
    }

    @Test
    func leavesEditedTransferOutOfRecentTransfers() async throws {
        let setup = try await Setup()
        try await setup.saveTransfer(3000, from: setup.cash, to: setup.bank, at: 1)
        try await setup.saveTransfer(1000, from: setup.bank, to: setup.cash, at: 2)
        let entries = try setup.database.snapshot().entries
        let edited = try #require(entries.first { $0.amount == 1000 })
        let model = EntryModel(
            parts: .system(setup.database),
            editing: edited.id,
            date: setup.date
        )

        await model.load()

        #expect(model.output.recentTransfers.map(\.amount) == [3000])
    }
}
