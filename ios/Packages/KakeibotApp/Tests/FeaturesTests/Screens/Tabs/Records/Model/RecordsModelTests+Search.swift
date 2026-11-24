import Core
import FeatureModels
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
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()

        model.state.searchText = "ランチ"
        let lunch = model.output.searchDays.map(\.date.description)

        model.state.searchText = "食費"
        let food = model.output.searchDays.map(\.date.description)

        model.state.searchText = "¥500"
        let amount = model.output.searchDays.map(\.date.description)

        model.state.searchText = " "
        let blank = model.output.searchDays

        #expect(lunch == ["2026-10-12"])
        #expect(food == ["2026-10-12", "2026-09-30"])
        #expect(amount == ["2026-09-30"])
        #expect(blank.isEmpty)
    }

    @Test
    func searchesItemNames() async throws {
        let setup = try await Setup()
        let items = [
            EntryItem.Draft(name: "牛乳", amount: 396),
            EntryItem.Draft(name: "食パン", amount: 220)
        ]
        try await setup.save(.expense, amount: 616, on: "2026-10-12", items: items)
        try await setup.save(.expense, amount: 500, on: "2026-10-11", memo: "コーヒー")
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()

        model.state.searchText = "牛乳"
        let milk = model.output.searchDays.map(\.date.description)

        model.state.searchText = "パン"
        let bread = model.output.searchDays.map(\.date.description)

        #expect(milk == ["2026-10-12"])
        #expect(bread == ["2026-10-12"])
    }

    @Test
    func listsItemsUnderRows() async throws {
        let setup = try await Setup()
        let items = [
            EntryItem.Draft(name: "牛乳", quantity: 2, amount: 396),
            EntryItem.Draft(name: "食パン", amount: 220)
        ]
        try await setup.save(.expense, amount: 616, on: "2026-10-12", items: items)
        try await setup.save(.expense, amount: 500, on: "2026-10-12", memo: "コーヒー")
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()
        let day = try #require(model.output.days.first)

        let rows = model.output.rows(for: day)

        #expect(rows.map(\.items.count).sorted() == [0, 2])
        #expect(rows.flatMap(\.items).map(\.name) == ["牛乳", "食パン"])
        #expect(rows.flatMap(\.items).map(\.quantity) == [2, 1])
    }

    @Test
    func filtersByCategoryAndSumsSearch() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30", memo: "ランチ")
        let options = try await setup.database.entryOptions()
        let food = try #require(options.expenseCategories.first)
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()

        model.state.searchText = "ランチ"
        let summary = model.output.searchSummary

        model.state.filter = EntryFilter(categoryIds: [food.id])
        let filtered = model.output.days.map(\.date.description)
        let title = model.output.filterTitle

        model.state.filter = EntryFilter()

        #expect(summary?.count == 2)
        #expect(summary?.expenseTotal == 1480)
        #expect(summary?.range.lowerBound.description == "2026-09-30")
        #expect(summary?.range.upperBound.description == "2026-10-12")
        #expect(filtered == ["2026-10-12"])
        #expect(title == food.name)
        #expect(model.output.days.count == 2)
    }

    @Test
    func tellsWhenFilterHidesEveryRecord() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        let options = try await setup.database.entryOptions()
        let salary = try #require(options.incomeCategories.first)
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()

        model.state.filter = EntryFilter(categoryIds: [salary.id])
        model.state.searchText = "ランチ"
        let isMonthHidden = model.output.isMonthHiddenByFilter
        let isSearchHidden = model.output.isSearchHiddenByFilter

        model.state.searchText = "コーヒー"
        let isMissingWordHidden = model.output.isSearchHiddenByFilter

        model.state.move(months: -1)
        let isEmptyMonthHidden = model.output.isMonthHiddenByFilter

        model.state.move(months: 1)
        model.state.clearFilter()

        #expect(isMonthHidden)
        #expect(isSearchHidden)
        #expect(!isMissingWordHidden)
        #expect(!isEmptyMonthHidden)
        #expect(model.state.filter.isEmpty)
        #expect(!model.output.isMonthHiddenByFilter)
        #expect(model.output.days.map(\.date.description) == ["2026-10-12"])
    }

    @Test
    func remembersSearchedWords() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)

        await model.rememberSearch("ランチ")
        await model.rememberSearch("本")
        let saved = try await setup.database.setting(.recentSearches)

        await model.clearRecentSearches()

        #expect(saved == ["本", "ランチ"])
        #expect(model.input.recentSearches.isEmpty)
    }

    @Test
    func restoresClearedSearches() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        await model.rememberSearch("ランチ")
        await model.rememberSearch("本")
        let words = model.input.recentSearches
        await model.clearRecentSearches()

        await model.restoreRecentSearches(words)
        let saved = try await setup.database.setting(.recentSearches)

        #expect(saved == ["本", "ランチ"])
    }

    @Test
    func countsSearchResultsHiddenByFilter() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        try await setup.save(.expense, amount: 500, on: "2026-09-30", memo: "ランチ")
        let options = try await setup.database.entryOptions()
        let salary = try #require(options.incomeCategories.first)
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()
        model.state.searchText = "ランチ"
        let unfiltered = model.output.searchHiddenCount

        model.state.filter = EntryFilter(categoryIds: [salary.id])
        let hidden = model.output.searchHiddenCount

        model.state.searchText = "コーヒー"
        let missing = model.output.searchHiddenCount

        #expect(unfiltered == 0)
        #expect(hidden == 2)
        #expect(missing == 0)
    }

    @Test
    func countsShownEntries() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30", memo: "ランチ")
        let options = try await setup.database.entryOptions()
        let food = try #require(options.expenseCategories.first)
        let salary = try #require(options.incomeCategories.first)
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        await model.load()
        let month = model.output.shownEntryCount

        model.state.filter = EntryFilter(categoryIds: [food.id])
        let filteredMonth = model.output.shownEntryCount

        model.state.isSearching = true
        let blankSearch = model.output.shownEntryCount

        model.state.searchText = "ランチ"
        let searched = model.output.shownEntryCount

        model.state.filter = EntryFilter(categoryIds: [salary.id])
        let hiddenSearch = model.output.shownEntryCount

        #expect(month == 2)
        #expect(filteredMonth == 1)
        #expect(blankSearch == 1)
        #expect(searched == 2)
        #expect(hiddenSearch == 0)
    }
}
