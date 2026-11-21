import Core
import Foundation
import Testing

struct ReviewCompareTests {
    @Test
    func averagesOnlyRecordedPeriods() throws {
        let entries = try [
            Self.entry("2026-09-10", 30000, Self.food),
            Self.entry("2026-08-10", 34000, Self.food),
            Self.entry("2026-10-10", 41200, Self.food)
        ]

        let compare = try Self.compare(entries)
        let row = try #require(compare.rows.first)

        #expect(compare.periods == 2)
        #expect(row.average == 32000)
        #expect(row.difference == 9200)
        #expect(row.tone == .more)
    }

    @Test
    func judgesSmallDifferenceAsUsual() throws {
        let entries = try [
            Self.entry("2026-09-10", 11500, Self.food),
            Self.entry("2026-10-10", 12000, Self.food)
        ]

        let compare = try Self.compare(entries)

        #expect(compare.rows.first?.tone == .usual)
    }

    @Test
    func leavesOutOneSpecialExpense() throws {
        let entries = try [
            Self.entry("2026-09-10", 8400, Self.goods),
            Self.entry("2026-10-08", 32000, Self.goods),
            Self.entry("2026-10-12", 6100, Self.goods)
        ]

        let compare = try Self.compare(entries)

        #expect(compare.special?.amount == 32000)
        #expect(compare.rows.first?.amount == 6100)
        #expect(compare.rows.first?.tone == .less)
    }

    @Test
    func hasNoRowsWithoutHistory() throws {
        let entries = try [Self.entry("2026-10-10", 41200, Self.food)]

        let compare = try Self.compare(entries)

        #expect(compare.periods == 0)
        #expect(compare.rows.isEmpty)
    }

    @Test
    func sortsByLargestDifference() throws {
        let entries = try [
            Self.entry("2026-09-10", 30000, Self.food),
            Self.entry("2026-09-11", 8400, Self.goods),
            Self.entry("2026-10-10", 31000, Self.food),
            Self.entry("2026-10-11", 4000, Self.goods)
        ]

        let compare = try Self.compare(entries)

        #expect(compare.rows.map(\.categoryId) == [Self.goods, Self.food])
    }
}

private extension ReviewCompareTests {
    static let food = EntryCategory.ID()
    static let goods = EntryCategory.ID()
    static let wallet = Wallet.ID()
    static let now = Date(timeIntervalSince1970: 1_794_000_000)

    static func entry(
        _ date: String,
        _ amount: Int,
        _ categoryId: EntryCategory.ID
    ) throws -> Entry {
        try Entry(
            type: .expense,
            amount: amount,
            date: #require(LocalDate(date)),
            categoryId: categoryId,
            walletId: wallet,
            createdAt: now,
            updatedAt: now
        )
    }

    static func compare(_ entries: [Entry]) throws -> ReviewCompare {
        let range = try month("2026-10")
        let history = try ["2026-09", "2026-08", "2026-07"].map(month)
        return ReviewCompare(entries: entries, in: range, history: history)
    }

    static func month(_ text: String) throws -> ClosedRange<LocalDate> {
        let month = try #require(YearMonth(text))
        return month.period(startingOn: .first)
    }
}
