import Core
import Foundation
import Store
import Testing

struct EntryListTests {
    @Test
    func publishesSavedEntries() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let category = options.expenseCategories[0]
        let date = try #require(LocalDate("2026-10-03"))

        let draft = EntryDraft(
            type: .expense,
            amount: 980,
            date: date,
            categoryId: category.id,
            walletId: options.wallets[0].id
        )

        var updates = database.entryListUpdates().makeAsyncIterator()
        let first = try await updates.next()

        #expect(first?.days.isEmpty == true)
        #expect(first?.categories[category.id] == category)

        let saved = try await database.saveEntry(draft, at: now)
        let second = try await updates.next()

        #expect(second?.days.map(\.date) == [date])
        #expect(second?.days.first?.entries == [saved])
        #expect(second?.days.first?.expenseTotal == 980)
    }

    @Test
    func readsListOnce() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let date = try #require(LocalDate("2026-10-03"))

        let draft = EntryDraft(
            type: .income,
            amount: 250_000,
            date: date,
            categoryId: options.incomeCategories[0].id,
            walletId: options.wallets[1].id
        )

        let saved = try await database.saveEntry(draft, at: now)
        let list = try await database.entryList()

        #expect(list.days.first?.entries == [saved])
        #expect(list.days.first?.incomeTotal == 250_000)
        #expect(list.wallets[saved.walletId]?.name == "銀行")
    }

    @Test
    func listsRecentMemosOnce() async throws {
        let database = try AppDatabase.inMemory()
        let start = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: start)
        let options = try await database.entryOptions()
        let date = try #require(LocalDate("2026-10-03"))
        let memos = ["ランチ", "", "コーヒー", "ランチ", "スーパー"]

        for (offset, memo) in memos.enumerated() {
            let draft = EntryDraft(
                type: .expense,
                amount: 500,
                date: date,
                categoryId: options.expenseCategories[0].id,
                walletId: options.wallets[0].id,
                memo: memo
            )

            let now = start.addingTimeInterval(TimeInterval(offset))
            try await database.saveEntry(draft, at: now)
        }

        let recent = try await database.recentMemos(limit: 2)

        #expect(recent == ["スーパー", "ランチ"])
    }

    @Test
    func optionsSkipArchivedAndFollowSortOrder() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let defaults = try await database.entryOptions()
        var archived = defaults.expenseCategories[0]
        archived.archivedAt = now
        var moved = defaults.wallets[0]
        moved.sortOrder = 9

        try await database.writer.write { [archived, moved] db in
            try archived.update(db)
            try moved.update(db)
        }

        let options = try await database.entryOptions()

        #expect(options.expenseCategories == Array(defaults.expenseCategories.dropFirst()))
        #expect(options.wallets.map(\.name) == ["銀行", "財布"])
    }
}
