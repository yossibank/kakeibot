import Core
import Features
import Foundation
import Store
import Testing

extension RecordsModelTests {
    struct Setup {
        let database: AppDatabase
        let today: LocalDate
    }
}

extension RecordsModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let today = try #require(LocalDate("2026-10-17"))

        try database.insertDefaultsIfEmpty(at: Date())
        self.init(database: database, today: today)
    }

    func save(
        _ type: Entry.Kind,
        amount: Int,
        on text: String,
        memo: String = "",
        items: [EntryItem.Draft] = []
    ) async throws {
        let options = try await database.entryOptions()
        let categories = type == .income ? options.incomeCategories : options.expenseCategories
        let date = try #require(LocalDate(text))
        let days = try await database.entryList().days
        let count = days.reduce(0) { $0 + $1.entries.count }
        let offset = TimeInterval(count)
        let createdAt = Date(timeIntervalSince1970: 1_791_000_000 + offset)

        let draft = EntryDraft(
            type: type,
            amount: amount,
            date: date,
            categoryId: categories.first?.id,
            walletId: options.wallets[0].id,
            memo: memo,
            items: items
        )

        try await database.saveEntry(draft, at: createdAt)
    }
}
