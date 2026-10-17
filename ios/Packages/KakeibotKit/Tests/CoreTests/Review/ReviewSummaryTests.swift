import Core
import Foundation
import Testing

struct ReviewSummaryTests {
    @Test(arguments: try summaryCases)
    func sumsEntriesInRange(fixture: SummaryCase) {
        let ids = Ids()
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let entries = fixture.entries.map { row in
            Entry(
                type: row.type,
                amount: row.amount,
                date: row.date,
                categoryId: row.category.flatMap { ids.categories[$0] },
                walletId: ids.wallet(row.wallet),
                createdAt: now,
                updatedAt: now
            )
        }

        let summary = ReviewSummary(
            entries: entries,
            in: fixture.start...fixture.end
        )

        #expect(ids.named(summary.expense) == fixture.expense)
        #expect(ids.named(summary.income) == fixture.income)
        #expect(summary.balance == fixture.balance)
    }
}

extension ReviewSummaryTests {
    struct SummaryCase: Decodable, Sendable {
        let start: LocalDate
        let end: LocalDate
        let entries: [Row]
        let expense: Totals
        let income: Totals
        let balance: Int
    }

    struct Row: Decodable, Sendable {
        let type: Entry.Kind
        let amount: Int
        let date: LocalDate
        let category: String?
        let wallet: String
    }

    struct Totals: Decodable, Equatable, Sendable {
        let total: Int
        let categories: [String: Int]
        let wallets: [String: Int]
    }

    struct Ids {
        let categories: [String: EntryCategory.ID] = [
            "food": EntryCategory.ID(),
            "daily": EntryCategory.ID(),
            "salary": EntryCategory.ID()
        ]

        let wallets: [String: Wallet.ID] = [
            "cash": Wallet.ID(),
            "card": Wallet.ID(),
            "bank": Wallet.ID()
        ]
    }
}

extension ReviewSummaryTests.Ids {
    func wallet(_ name: String) -> Wallet.ID {
        wallets[name] ?? Wallet.ID()
    }

    func named(
        _ breakdown: ReviewSummary.Breakdown
    ) -> ReviewSummaryTests.Totals {
        let categoryNames = Dictionary(
            uniqueKeysWithValues: categories.map { ($1, $0) }
        )

        let walletNames = Dictionary(
            uniqueKeysWithValues: wallets.map { ($1, $0) }
        )

        let byCategory = breakdown.byCategory.map { id, amount in
            (categoryNames[id] ?? id.description, amount)
        }

        let byWallet = breakdown.byWallet.map { id, amount in
            (walletNames[id] ?? id.description, amount)
        }

        return ReviewSummaryTests.Totals(
            total: breakdown.total,
            categories: Dictionary(uniqueKeysWithValues: byCategory),
            wallets: Dictionary(uniqueKeysWithValues: byWallet)
        )
    }
}

private extension ReviewSummaryTests {
    static var summaryCases: [SummaryCase] {
        get throws {
            try Fixture.load("review/review-summary.json")
        }
    }
}
