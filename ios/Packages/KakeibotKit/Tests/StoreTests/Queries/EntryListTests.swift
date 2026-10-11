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
}
