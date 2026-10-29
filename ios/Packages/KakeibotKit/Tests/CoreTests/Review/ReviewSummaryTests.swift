import Core
import Foundation
import Testing

struct ReviewSummaryTests {
    @Test(arguments: try summaryCases)
    func sumsEntriesInRange(fixture: SummaryCase) {
        let ids = Ids()
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let range = fixture.start...fixture.end

        let entries = fixture.entries.map { row in
            let categoryId = row.category.flatMap { ids.categories[$0] }
            let walletId = ids.wallet(row.wallet)

            return Entry(
                type: row.type,
                amount: row.amount,
                date: row.date,
                categoryId: categoryId,
                walletId: walletId,
                createdAt: now,
                updatedAt: now
            )
        }

        let summary = ReviewSummary(entries: entries, in: range)

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

    func named(_ breakdown: ReviewSummary.Breakdown) -> ReviewSummaryTests.Totals {
        let categoryPairs = categories.map { ($1, $0) }
        let walletPairs = wallets.map { ($1, $0) }
        let categoryNames = Dictionary(uniqueKeysWithValues: categoryPairs)
        let walletNames = Dictionary(uniqueKeysWithValues: walletPairs)

        let byCategory = breakdown.byCategory.map { id, amount in
            (categoryNames[id] ?? id.description, amount)
        }

        let byWallet = breakdown.byWallet.map { id, amount in
            (walletNames[id] ?? id.description, amount)
        }

        let categoryTotals = Dictionary(uniqueKeysWithValues: byCategory)
        let walletTotals = Dictionary(uniqueKeysWithValues: byWallet)

        return ReviewSummaryTests.Totals(
            total: breakdown.total,
            categories: categoryTotals,
            wallets: walletTotals
        )
    }
}

private extension ReviewSummaryTests {
    static var summaryCases: [SummaryCase] {
        get throws {
            try Fixture.cases("review/review-summary.json")
        }
    }
}
