import Core
import Features
import Foundation
import Store
import Testing

extension RecordsModelTests {
    @Test
    func searchesAcrossMonths() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30", memo: "コーヒー")
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()

        model.searchText = "ランチ"
        let lunch = model.searchDays.map(\.date.description)

        model.searchText = "食費"
        let food = model.searchDays.map(\.date.description)

        model.searchText = "¥500"
        let amount = model.searchDays.map(\.date.description)

        model.searchText = " "
        let blank = model.searchDays

        #expect(lunch == ["2026-10-12"])
        #expect(food == ["2026-10-12", "2026-09-30"])
        #expect(amount == ["2026-09-30"])
        #expect(blank.isEmpty)
    }

    @Test
    func filtersByCategoryAndSumsSearch() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30", memo: "ランチ")
        let options = try await setup.database.entryOptions()
        let food = try #require(options.expenseCategories.first)
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()

        model.searchText = "ランチ"
        let summary = model.searchSummary

        model.filter = EntryFilter(categoryIds: [food.id])
        let filtered = model.days.map(\.date.description)
        let title = model.filterTitle

        model.filter = EntryFilter()

        #expect(summary?.count == 2)
        #expect(summary?.expenseTotal == 1480)
        #expect(summary?.range.lowerBound.description == "2026-09-30")
        #expect(summary?.range.upperBound.description == "2026-10-12")
        #expect(filtered == ["2026-10-12"])
        #expect(title == food.name)
        #expect(model.days.count == 2)
    }

    @Test
    func tellsWhenFilterHidesEveryRecord() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        let options = try await setup.database.entryOptions()
        let salary = try #require(options.incomeCategories.first)
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()

        model.filter = EntryFilter(categoryIds: [salary.id])
        model.searchText = "ランチ"
        let isMonthHidden = model.isMonthHiddenByFilter
        let isSearchHidden = model.isSearchHiddenByFilter

        model.searchText = "コーヒー"
        let isMissingWordHidden = model.isSearchHiddenByFilter

        model.move(months: -1)
        let isEmptyMonthHidden = model.isMonthHiddenByFilter

        model.move(months: 1)
        model.clearFilter()

        #expect(isMonthHidden)
        #expect(isSearchHidden)
        #expect(!isMissingWordHidden)
        #expect(!isEmptyMonthHidden)
        #expect(model.filter.isEmpty)
        #expect(!model.isMonthHiddenByFilter)
        #expect(model.days.map(\.date.description) == ["2026-10-12"])
    }

    @Test
    func remembersSearchedWords() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, today: setup.today)

        await model.rememberSearch("ランチ")
        await model.rememberSearch("本")
        let saved = try await setup.database.setting(.recentSearches)

        await model.clearRecentSearches()

        #expect(saved == ["本", "ランチ"])
        #expect(model.recentSearches.isEmpty)
    }
}
