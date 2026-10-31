import Core
import Foundation
import Store
import Testing

struct EntryHistoryTests {
    @Test
    func returnsCountAndOldestCreatedAt() async throws {
        let database = try AppDatabase.inMemory()
        let first = Date(timeIntervalSince1970: 1_791_000_000)
        let later = first.addingTimeInterval(86400)
        try database.insertDefaultsIfEmpty(at: first)
        let draft = try await expenseDraft(in: database)

        try await database.saveEntry(draft, at: later)
        try await database.saveEntry(draft, at: first)
        try await database.saveEntry(draft, at: later)
        let history = try await database.entryHistory()

        #expect(history == EntryHistory(count: 3, firstCreatedAt: first))
    }

    @Test
    func returnsNothingWithoutEntries() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date(timeIntervalSince1970: 1_791_000_000))

        let history = try await database.entryHistory()

        #expect(history.count == 0)
        #expect(history.firstCreatedAt == nil)
    }

    @Test
    func countsSingleEntry() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let draft = try await expenseDraft(in: database)

        try await database.saveEntry(draft, at: now)
        let history = try await database.entryHistory()

        #expect(history == EntryHistory(count: 1, firstCreatedAt: now))
    }
}

private extension EntryHistoryTests {
    func expenseDraft(in database: AppDatabase) async throws -> EntryDraft {
        let options = try await database.entryOptions()
        let date = try #require(LocalDate("2026-10-03"))

        return EntryDraft(
            type: .expense,
            amount: 980,
            date: date,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id
        )
    }
}
