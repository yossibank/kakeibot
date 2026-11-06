import Core
import Features
import Foundation
import Store
import Testing

extension RecordsModelTests {
    @Test
    func selectsAndClearsWholeDay() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.expense, amount: 220, on: "2026-10-12")
        try await setup.save(.expense, amount: 500, on: "2026-10-10")
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        let dayDate = try #require(LocalDate("2026-10-12"))
        let otherDate = try #require(LocalDate("2026-10-10"))
        let day = try #require(model.day(on: dayDate))
        let other = try #require(model.day(on: otherDate))
        let otherId = try #require(other.entries.first?.id)
        let dayIds = Set(day.entries.map(\.id))

        let firstId = try #require(day.entries.first?.id)
        let partly: Set<Entry.ID> = [firstId, otherId]
        let selected = model.toggling(day, in: partly)
        let cleared = model.toggling(day, in: selected)

        #expect(model.isSelected(day, in: partly) == false)
        #expect(selected == dayIds.union([otherId]))
        #expect(model.isSelected(day, in: selected))
        #expect(cleared == [otherId])
        #expect(model.isSelected(day, in: cleared) == false)
    }

    @Test
    func togglesOneEntry() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        let id = try #require(model.days.first?.entries.first?.id)

        let selected = model.toggling(id, in: [])
        let cleared = model.toggling(id, in: selected)

        #expect(selected == [id])
        #expect(cleared.isEmpty)
    }

    @Test
    func selectsAllShownInMonth() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30")
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        let monthIds = model.days.flatMap(\.entries).map(\.id)

        let all = model.selectingAllShown(in: [])

        #expect(model.shownEntryIDs.count == 2)
        #expect(all == Set(monthIds))
        #expect(model.selectsAllShown(all))
        #expect(model.selectsAllShown([]) == false)
    }

    @Test
    func selectsAllShownByFilterAndSearch() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30", memo: "ランチ")
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        let expenseDay = try #require(model.days.first)
        let expenseId = try #require(expenseDay.entries.first?.id)
        let category = try #require(expenseDay.entries.first?.categoryId)

        model.filter = EntryFilter(categoryIds: [category])
        let filtered = model.selectingAllShown(in: [])

        model.filter = EntryFilter()
        model.isSearching = true
        model.searchText = "ランチ"
        let searched = model.selectingAllShown(in: [])

        #expect(filtered == [expenseId])
        #expect(searched.count == 2)
        #expect(searched.contains(expenseId))
    }

    @Test
    func doesNotSelectAllWhenNothingShown() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()

        #expect(model.shownEntryIDs.isEmpty)
        #expect(model.selectingAllShown(in: []).isEmpty)
        #expect(model.selectsAllShown([]) == false)
    }
}

extension RecordsModelTests {
    @Test
    func allowsBatchChangeOfOneType() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.expense, amount: 220, on: "2026-10-11")
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        let ids = Set(model.shownEntryIDs)

        #expect(model.batchCategoryBlock(of: ids) == nil)
        #expect(model.batchWalletBlock(of: ids) == nil)
        #expect(model.batchDeleteBlock(of: ids) == nil)
    }

    @Test
    func blocksCategoryWhenTypesAreMixed() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        let ids = Set(model.shownEntryIDs)

        #expect(model.batchCategoryBlock(of: ids) == "支出と収入が混ざっているので、カテゴリはまとめて変えられません")
        #expect(model.batchWalletBlock(of: ids) == nil)
    }

    @Test
    func blocksCategoryAndWalletWithTransfer() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        let options = try await setup.database.entryOptions()
        let date = try #require(LocalDate("2026-10-11"))

        let transfer = EntryDraft(
            type: .transfer,
            amount: 10000,
            date: date,
            categoryId: nil,
            walletId: options.wallets[1].id,
            toWalletId: options.wallets[0].id
        )

        try await setup.database.saveEntry(transfer, at: Date())
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        let ids = Set(model.shownEntryIDs)

        #expect(ids.count == 2)
        #expect(model.batchCategoryBlock(of: ids) == "振替を含むので、カテゴリはまとめて変えられません")
        #expect(model.batchWalletBlock(of: ids) == "振替を含むので、口座はまとめて変えられません")
    }

    @Test
    func blocksBatchWhenNothingSelected() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()

        #expect(model.batchCategoryBlock(of: []) == "記録を選んでください")
        #expect(model.batchWalletBlock(of: []) == "記録を選んでください")
        #expect(model.batchDeleteBlock(of: []) == "記録を選んでください")
    }
}
