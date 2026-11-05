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
    func searchesItemNames() async throws {
        let setup = try await Setup()
        let items = [
            EntryItem.Draft(name: "牛乳", amount: 396),
            EntryItem.Draft(name: "食パン", amount: 220)
        ]
        try await setup.save(.expense, amount: 616, on: "2026-10-12", items: items)
        try await setup.save(.expense, amount: 500, on: "2026-10-11", memo: "コーヒー")
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()

        model.searchText = "牛乳"
        let milk = model.searchDays.map(\.date.description)

        model.searchText = "パン"
        let bread = model.searchDays.map(\.date.description)

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
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        let day = try #require(model.days.first)

        let rows = model.rows(for: day)

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

    @Test
    func restoresClearedSearches() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.rememberSearch("ランチ")
        await model.rememberSearch("本")
        let words = model.recentSearches
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
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        model.searchText = "ランチ"
        let unfiltered = model.searchHiddenCount

        model.filter = EntryFilter(categoryIds: [salary.id])
        let hidden = model.searchHiddenCount

        model.searchText = "コーヒー"
        let missing = model.searchHiddenCount

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
        let model = RecordsModel(database: setup.database, today: setup.today)
        await model.load()
        let month = model.shownEntryCount

        model.filter = EntryFilter(categoryIds: [food.id])
        let filteredMonth = model.shownEntryCount

        model.isSearching = true
        let blankSearch = model.shownEntryCount

        model.searchText = "ランチ"
        let searched = model.shownEntryCount

        model.filter = EntryFilter(categoryIds: [salary.id])
        let hiddenSearch = model.shownEntryCount

        #expect(month == 2)
        #expect(filteredMonth == 1)
        #expect(blankSearch == 1)
        #expect(searched == 2)
        #expect(hiddenSearch == 0)
    }
}
