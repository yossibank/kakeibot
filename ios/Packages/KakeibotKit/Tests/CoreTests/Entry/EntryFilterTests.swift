import Core
import Foundation
import Testing

struct EntryFilterTests {
    @Test(arguments: try cases)
    func keepsChosenEntries(fixture: FilterCase) {
        let filter = EntryFilter(
            categoryIds: Set(fixture.categories),
            walletIds: Set(fixture.wallets)
        )

        let days = EntryDay.grouping(fixture.entries.map(\.entry))

        let kept = filter.apply(to: days).flatMap(\.entries)

        #expect(kept.map(\.id) == fixture.keptIds)
    }
}

extension EntryFilterTests {
    struct FilterCase: Decodable, Sendable {
        let categories: [EntryCategory.ID]
        let wallets: [Wallet.ID]
        let entries: [EntryItem]
        let keptIds: [Entry.ID]
    }

    struct EntryItem: Decodable, Sendable {
        let id: Entry.ID
        let category: EntryCategory.ID?
        let wallet: Wallet.ID
        let toWallet: Wallet.ID?
        let date: LocalDate
    }
}

extension EntryFilterTests.EntryItem {
    var entry: Entry {
        let createdAt = Date(timeIntervalSince1970: 1_791_000_000)

        return Entry(
            id: id,
            type: .expense,
            amount: 100,
            date: date,
            categoryId: category,
            walletId: wallet,
            toWalletId: toWallet,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}

private extension EntryFilterTests {
    static var cases: [FilterCase] {
        get throws {
            try Fixture.load("entry/entry-filter.json")
        }
    }
}
