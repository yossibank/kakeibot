import Core
import FeatureModels
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
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let dayDate = try #require(LocalDate("2026-10-12"))
        let otherDate = try #require(LocalDate("2026-10-10"))
        let day = try #require(model.output.day(on: dayDate))
        let other = try #require(model.output.day(on: otherDate))
        let otherId = try #require(other.entries.first?.id)
        let dayIds = Set(day.entries.map(\.id))

        let firstId = try #require(day.entries.first?.id)
        let partly: Set<Entry.ID> = [firstId, otherId]
        let selected = model.output.toggling(day, in: partly)
        let cleared = model.output.toggling(day, in: selected)

        #expect(model.output.isSelected(day, in: partly) == false)
        #expect(selected == dayIds.union([otherId]))
        #expect(model.output.isSelected(day, in: selected))
        #expect(cleared == [otherId])
        #expect(model.output.isSelected(day, in: cleared) == false)
    }

    @Test
    func togglesOneEntry() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let id = try #require(model.output.days.first?.entries.first?.id)

        let selected = model.output.toggling(id, in: [])
        let cleared = model.output.toggling(id, in: selected)

        #expect(selected == [id])
        #expect(cleared.isEmpty)
    }

    @Test
    func selectsAllShownInMonth() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30")
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let monthIds = model.output.days.flatMap(\.entries).map(\.id)

        let all = model.output.selectingAllShown(in: [])

        #expect(model.output.shownEntryIDs.count == 2)
        #expect(all == Set(monthIds))
        #expect(model.output.selectsAllShown(all))
        #expect(model.output.selectsAllShown([]) == false)
    }

    @Test
    func selectsAllShownByFilterAndSearch() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30", memo: "ランチ")
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let expenseDay = try #require(model.output.days.first)
        let expenseId = try #require(expenseDay.entries.first?.id)
        let category = try #require(expenseDay.entries.first?.categoryId)

        model.state.fields.filter = EntryFilter(categoryIds: [category])
        let filtered = model.output.selectingAllShown(in: [])

        model.state.fields.filter = EntryFilter()
        model.state.fields.isSearching = true
        model.state.fields.searchText = "ランチ"
        let searched = model.output.selectingAllShown(in: [])

        #expect(filtered == [expenseId])
        #expect(searched.count == 2)
        #expect(searched.contains(expenseId))
    }

    @Test
    func doesNotSelectAllWhenNothingShown() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        await model.load()

        #expect(model.output.shownEntryIDs.isEmpty)
        #expect(model.output.selectingAllShown(in: []).isEmpty)
        #expect(model.output.selectsAllShown([]) == false)
    }
}

extension RecordsModelTests {
    @Test
    func allowsBatchChangeOfOneType() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.expense, amount: 220, on: "2026-10-11")
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let ids = Set(model.output.shownEntryIDs)

        #expect(model.output.batchCategoryBlock(of: ids) == nil)
        #expect(model.output.batchWalletBlock(of: ids) == nil)
        #expect(model.output.batchDeleteBlock(of: ids) == nil)
    }

    @Test
    func blocksCategoryWhenTypesAreMixed() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let ids = Set(model.output.shownEntryIDs)

        #expect(model.output.batchCategoryBlock(of: ids) == "支出と収入が混ざっているので、カテゴリはまとめて変えられません")
        #expect(model.output.batchWalletBlock(of: ids) == nil)
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
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let ids = Set(model.output.shownEntryIDs)

        #expect(ids.count == 2)
        #expect(model.output.batchCategoryBlock(of: ids) == "振替を含むので、カテゴリはまとめて変えられません")
        #expect(model.output.batchWalletBlock(of: ids) == "振替を含むので、口座はまとめて変えられません")
    }

    @Test
    func blocksBatchWhenNothingSelected() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        await model.load()

        #expect(model.output.batchCategoryBlock(of: []) == "記録を選んでください")
        #expect(model.output.batchWalletBlock(of: []) == "記録を選んでください")
        #expect(model.output.batchDeleteBlock(of: []) == "記録を選んでください")
    }
}
