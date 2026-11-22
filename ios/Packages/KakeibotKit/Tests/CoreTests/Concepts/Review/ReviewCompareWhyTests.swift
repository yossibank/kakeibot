import Core
import Foundation
import Testing

struct ReviewCompareWhyTests {
    @Test
    func joinsTheMemoAndTheWeekend() throws {
        let entries = try Self.entries("2026-10", days: [2, 3, 9, 10, 4], memo: "外食")
            + Self.entries("2026-09", days: [0, 1])

        let why = try Self.why(entries)

        #expect(why?.text == "「外食」の記録が 5 件あり、5 件のうち 4 件が土日でした。")
    }

    @Test
    func tellsTheMemoAlone() throws {
        let entries = try Self.entries("2026-10", days: [0, 1, 4, 5], memo: "外食")
            + Self.entries("2026-09", days: [0])

        let why = try Self.why(entries)

        #expect(why?.text == "「外食」の記録が 4 件ありました。")
        #expect(why?.memo == "外食")
    }

    @Test
    func marksTheNumbers() throws {
        let entries = try Self.entries("2026-10", days: [0, 1, 4, 5], memo: "外食")
            + Self.entries("2026-09", days: [0])

        let why = try Self.why(entries)

        #expect(why?.parts == [.text("「外食」の記録が "), .number("4"), .text(" 件ありました。")])
    }

    @Test
    func tellsTheCountWithoutAMemo() throws {
        let entries = try Self.entries("2026-10", days: [0, 1, 4, 5])
            + Self.entries("2026-09", days: [0])

        let why = try Self.why(entries)

        #expect(why?.text == "記録が 4 件で、いつもの 1 件より多めでした。")
    }

    @Test
    func tellsTheLargeEntry() throws {
        let entries = try Self.entries("2026-10", days: [0])
            + Self.entries("2026-10", days: [1], amount: 8000)
            + Self.entries("2026-09", days: [0, 1])

        let why = try Self.why(entries)

        #expect(why?.text == "8,000円 の記録が 1 件ありました。")
    }

    @Test
    func tellsThePriceWhenTheCountStays() throws {
        let entries = try Self.entries("2026-10", days: [0])
            + Self.entries("2026-09", days: [0])

        let why = try Self.why(entries)

        #expect(why?.text == "1 回あたりの額が、いつもより高めでした。")
    }
}

private extension ReviewCompareWhyTests {
    static let food = EntryCategory.ID()
    static let wallet = Wallet.ID()
    static let now = Date(timeIntervalSince1970: 1_794_000_000)

    static func entries(
        _ month: String,
        days: [Int],
        amount: Int = 1000,
        memo: String? = nil
    ) throws -> [Entry] {
        let start = try Self.month(month).lowerBound

        return days.map { day in
            Entry(
                type: .expense,
                amount: amount,
                date: start.adding(days: day),
                categoryId: food,
                walletId: wallet,
                memo: memo,
                createdAt: now,
                updatedAt: now
            )
        }
    }

    static func why(_ entries: [Entry]) throws -> ReviewCompare.Why? {
        let range = try month("2026-10")
        let history = try ["2026-09", "2026-08", "2026-07"].map(month)

        return ReviewCompare.why(
            entries: entries,
            categoryId: food,
            in: range,
            history: history
        )
    }

    static func month(_ text: String) throws -> ClosedRange<LocalDate> {
        let month = try #require(YearMonth(text))
        return month.period(startingOn: .first)
    }
}
