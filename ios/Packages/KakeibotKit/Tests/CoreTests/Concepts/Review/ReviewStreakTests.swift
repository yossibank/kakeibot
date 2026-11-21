import Core
import Foundation
import Testing

struct ReviewStreakTests {
    @Test
    func countsDaysAndLongestRun() throws {
        let entries = try [
            Self.entry("2026-10-01"),
            Self.entry("2026-10-02"),
            Self.entry("2026-10-02"),
            Self.entry("2026-10-03"),
            Self.entry("2026-10-05"),
            Self.entry("2026-10-06")
        ]

        let streak = try ReviewStreak(entries: entries, in: Self.month("2026-10"))

        #expect(streak.days.count == 5)
        #expect(streak.longest == 3)
        #expect(streak.count == 6)
    }

    @Test
    func skipsRecurringEntries() throws {
        let entries = try [Self.entry("2026-10-01", recurringId: Recurring.ID())]

        let streak = try ReviewStreak(entries: entries, in: Self.month("2026-10"))

        #expect(streak.days.isEmpty)
        #expect(streak.count == 0)
    }

    @Test
    func countsContinuingPeriodsUntilTheFirstGap() throws {
        let entries = try [
            Self.entry("2026-10-01"),
            Self.entry("2026-09-01"),
            Self.entry("2026-07-01")
        ]

        let periods = try ["2026-10", "2026-09", "2026-08", "2026-07"].map(Self.month)
        let count = ReviewStreak.continuing(entries: entries, periods: periods)

        #expect(count == 2)
    }
}

private extension ReviewStreakTests {
    static let wallet = Wallet.ID()
    static let now = Date(timeIntervalSince1970: 1_794_000_000)

    static func entry(
        _ date: String,
        recurringId: Recurring.ID? = nil
    ) throws -> Entry {
        try Entry(
            type: .expense,
            amount: 1000,
            date: #require(LocalDate(date)),
            categoryId: nil,
            walletId: wallet,
            recurringId: recurringId,
            createdAt: now,
            updatedAt: now
        )
    }

    static func month(_ text: String) throws -> ClosedRange<LocalDate> {
        let month = try #require(YearMonth(text))
        return month.period(startingOn: .first)
    }
}
