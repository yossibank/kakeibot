import Core
import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
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
        let bill = model.billText
        let change = await model.save()

        #expect(dates == ["2026-11-27", "2026-12-27", "2027-01-27"])
        #expect(name == "カード")
        #expect(bill == "1/27払い")
        #expect(change?.entry.billMonth == later.yearMonth)

        model.date = try #require(LocalDate("2026-10-13"))

        #expect(model.billMonth == nil)
    }

    @Test
    func leavesOutFutureEntriesFromBalance() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let cash = try #require(options.wallets.first)
        let today = LocalDate(Date(), in: .current)
        let futureDate = today.adding(days: 3)

        let income = EntryDraft(
            type: .income,
            amount: 1000,
            date: today,
            categoryId: options.incomeCategories[0].id,
            walletId: cash.id
        )

        let future = EntryDraft(
            type: .expense,
            amount: 400,
            date: futureDate,
            categoryId: options.expenseCategories[0].id,
            walletId: cash.id
        )

        try await setup.database.saveEntry(income, at: Date())
        try await setup.database.saveEntry(future, at: Date())
        let model = EntryModel(database: setup.database, date: setup.date)

        await model.load()

        #expect(model.balance(of: cash) == 1000)
    }

    @Test
    func startsWithFirstWallet() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let categories = options.expenseCategories
        let wallets = options.wallets
        try await setup.saveEntry(category: categories[0].id, wallet: wallets[1].id, at: 1)
        let model = EntryModel(database: setup.database, date: setup.date)

        await model.load()
        let first = model.walletId
        model.categoryId = categories[1].id
        let second = model.walletId

        #expect(first == wallets[0].id)
        #expect(second == wallets[0].id)
        #expect(model.isUsualWallet)
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
    func offersSharedCategoriesForSharedWallet() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let shared = options.wallets[1]
        try await setup.database.startSharing(shared.id)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        let own = model.selectedCategory

        model.walletId = shared.id
        let sharedCategory = model.selectedCategory
        let walletIDs = Set(model.categories.map(\.walletId))

        model.walletId = options.wallets[0].id
        let back = model.selectedCategory

        #expect(sharedCategory?.name == own?.name)
        #expect(sharedCategory?.walletId == shared.id)
        #expect(walletIDs == [shared.id])
        #expect(back == own)
    }
}
