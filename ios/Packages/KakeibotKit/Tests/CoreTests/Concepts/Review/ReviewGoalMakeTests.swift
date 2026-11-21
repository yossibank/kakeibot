import Core
import Foundation
import Testing

struct ReviewGoalMakeTests {
    @Test
    func makesCountGoalForTheRisingMemo() throws {
        let entries = try Self.entries("2026-09", count: 5, amount: 1500, memo: "外食")
            + Self.entries("2026-10", count: 9, amount: 1500, memo: "外食")

        let goal = try #require(try Self.make(entries))

        #expect(goal.kind == .count)
        #expect(goal.memo == "外食")
        #expect(goal.baseline == 9)
        #expect(goal.target == 7)
        #expect(goal.saving == 3000)
        #expect(goal.period == "month:2026-11-01")
    }

    @Test
    func makesAverageGoalWhenPriceRises() throws {
        let entries = try Self.entries("2026-09", count: 5, amount: 1000)
            + Self.entries("2026-10", count: 5, amount: 2000)

        let goal = try #require(try Self.make(entries))

        #expect(goal.kind == .average)
        #expect(goal.memo == nil)
        #expect(goal.baseline == 2000)
        #expect(goal.target == 1500)
        #expect(goal.saving == 2500)
    }

    @Test
    func restsWithoutARisingCategory() throws {
        let entries = try Self.entries("2026-09", count: 5, amount: 1000)
            + Self.entries("2026-10", count: 5, amount: 1000)

        #expect(try Self.make(entries) == nil)
    }

    @Test
    func checksTheResultAndSavedAmount() throws {
        let goal = ReviewGoal(
            period: "month:2026-11-01",
            kind: .count,
            categoryId: Self.food,
            memo: "外食",
            baseline: 9,
            target: 7,
            saving: 3000,
            createdAt: Self.now
        )

        let entries = try Self.entries("2026-11", count: 6, amount: 1500, memo: "外食")
        let checked = try goal.checked(entries: entries, in: Self.month("2026-11"), now: Self.now)

        #expect(checked.result == 6)
        #expect(checked.saved == 4500)
        #expect(checked.isAchieved == true)
        #expect(checked.checkedAt == Self.now)
    }
}

private extension ReviewGoalMakeTests {
    static let food = EntryCategory.ID()
    static let wallet = Wallet.ID()
    static let now = Date(timeIntervalSince1970: 1_794_000_000)

    static func entries(
        _ month: String,
        count: Int,
        amount: Int,
        memo: String? = nil
    ) throws -> [Entry] {
        let start = try Self.month(month).lowerBound

        return (0..<count).map { index in
            Entry(
                type: .expense,
                amount: amount,
                date: start.adding(days: index),
                categoryId: food,
                walletId: wallet,
                memo: memo,
                createdAt: now,
                updatedAt: now
            )
        }
    }

    static func make(_ entries: [Entry]) throws -> ReviewGoal? {
        let range = try month("2026-10")
        let history = try ["2026-09", "2026-08", "2026-07"].map(month)

        return ReviewGoal.make(
            entries: entries,
            closed: range,
            history: history,
            period: "month:2026-11-01",
            now: now
        )
    }

    static func month(_ text: String) throws -> ClosedRange<LocalDate> {
        let month = try #require(YearMonth(text))
        return month.period(startingOn: .first)
    }
}
