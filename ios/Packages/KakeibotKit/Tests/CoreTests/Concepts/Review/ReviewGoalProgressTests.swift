import Core
import Foundation
import Testing

struct ReviewGoalProgressTests {
    @Test
    func countsEntriesOfTheCategory() throws {
        let goal = Self.goal(kind: .count, target: 7)
        let entries = try [
            Self.entry(day: 2, amount: 1000),
            Self.entry(day: 9, amount: 2000),
            Self.entry(day: 25, amount: 3000),
            Self.entry(day: 3, amount: 500, categoryId: Self.other),
            Self.entry(day: 4, amount: 800, type: .income)
        ]

        let progress = try Self.progress(of: goal, entries: entries)

        #expect(progress.count == 2)
        #expect(progress.amount == 3000)
        #expect(progress.projectedCount == 2)
        #expect(goal.current(of: progress) == 2)
        #expect(goal.isOnTrack(progress))
    }

    @Test
    func matchesMemoAfterNormalizing() throws {
        let goal = Self.goal(kind: .count, target: 7, memo: "ライフ")
        let entries = try [
            Self.entry(day: 2, amount: 1000, memo: " ﾗｲﾌ "),
            Self.entry(day: 3, amount: 1000, memo: "セブン")
        ]

        let progress = try Self.progress(of: goal, entries: entries)

        #expect(progress.count == 1)
    }

    @Test
    func judgesAverageAgainstTarget() throws {
        let goal = Self.goal(kind: .average, target: 2000)
        let entries = try [
            Self.entry(day: 2, amount: 1500),
            Self.entry(day: 9, amount: 3000)
        ]

        let progress = try Self.progress(of: goal, entries: entries)

        #expect(goal.current(of: progress) == 2250)
        #expect(!goal.isOnTrack(progress))
    }

    @Test
    func projectsCountToTheEndOfPeriod() throws {
        let goal = Self.goal(kind: .count, target: 7)
        let entries = try (1...6).map { try Self.entry(day: $0, amount: 1000) }

        let progress = try Self.progress(of: goal, entries: entries)

        #expect(progress.projectedCount == 8)
        #expect(!goal.isOnTrack(progress))
    }
}

private extension ReviewGoalProgressTests {
    static let food = EntryCategory.ID()
    static let other = EntryCategory.ID()
    static let wallet = Wallet.ID()
    static let now = Date(timeIntervalSince1970: 1_794_000_000)

    static func goal(
        kind: ReviewGoal.Kind,
        target: Int,
        memo: String? = nil
    ) -> ReviewGoal {
        ReviewGoal(
            period: "month:2026-11-01",
            kind: kind,
            categoryId: food,
            memo: memo,
            baseline: 9,
            target: target,
            saving: 5000,
            createdAt: now
        )
    }

    static func entry(
        day: Int,
        amount: Int,
        categoryId: EntryCategory.ID = food,
        type: Entry.Kind = .expense,
        memo: String? = nil
    ) throws -> Entry {
        try Entry(
            type: type,
            amount: amount,
            date: #require(LocalDate(year: 2026, month: 11, day: day)),
            categoryId: categoryId,
            walletId: wallet,
            memo: memo,
            createdAt: now,
            updatedAt: now
        )
    }

    static func progress(
        of goal: ReviewGoal,
        entries: [Entry]
    ) throws -> ReviewGoal.Progress {
        let start = try #require(LocalDate("2026-11-01"))
        let end = try #require(LocalDate("2026-11-30"))
        let today = try #require(LocalDate("2026-11-21"))
        return goal.progress(of: entries, in: start...end, today: today)
    }
}
