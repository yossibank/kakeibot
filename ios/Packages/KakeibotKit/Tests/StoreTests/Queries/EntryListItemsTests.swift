import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct EntryListItemsTests {
    @Test
    func readsItemsOnlyOfRequestedEntries() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()
        let date = try #require(LocalDate("2026-10-03"))
        let shown = try await database.saveEntry(
            receipt(
                "牛乳",
                date: date,
                options: options
            ),
            at: now
        )
        let hidden = try await database.saveEntry(
            receipt(
                "食パン",
                date: date,
                options: options
            ),
            at: now
        )

        let (withItems, withoutItems) = try await database.writer.read { db in
            let request = Entry.filter(key: shown.id)

            return try (
                AppDatabase.entryList(
                    of: request,
                    in: db,
                    includesItems: true
                ),
                AppDatabase.entryList(of: request, in: db)
            )
        }

        #expect(withItems.items[shown.id]?.map(\.name) == ["牛乳"])
        #expect(withItems.items[hidden.id] == nil)
        #expect(withoutItems.items.isEmpty)
    }
}

private extension EntryListItemsTests {
    func receipt(
        _ name: String,
        date: LocalDate,
        options: EntryOptions
    ) -> EntryDraft {
        EntryDraft(
            type: .expense,
            amount: 300,
            date: date,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            items: [EntryItem.Draft(name: name, amount: 300)]
        )
    }
}
