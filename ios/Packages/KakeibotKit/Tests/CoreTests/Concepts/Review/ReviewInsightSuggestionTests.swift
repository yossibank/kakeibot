import Core
import Testing

struct ReviewInsightSuggestionTests {
    @Test
    func fillsValuesFromFact() throws {
        let food = ReviewInsight.Category(name: "食費", amount: 58200, previous: 49300, budget: 60000)
        let input = Self.input(isCurrent: true, categories: [food])

        let insight = try #require(ReviewInsight.pick(from: input).first)

        #expect(insight.kind == .budgetPace)
        #expect(insight.suggestions.count == 5)
        #expect(insight.suggestions.allSatisfy { $0.contains("食費") && $0.contains("150円") })
    }

    @Test
    func rotatesByPeriod() throws {
        let food = ReviewInsight.Category(name: "食費", amount: 64200, previous: 60000, budget: 60000)
        let input = Self.input(isCurrent: false, categories: [food])
        let insight = try #require(ReviewInsight.pick(from: input).first)
        let start = try Self.period()

        let picked = (0..<5).map { insight.suggestion(in: start.adding($0)) }

        #expect(Set(picked).count == 5)
        #expect(insight.suggestion(in: start) == insight.suggestion(in: start.adding(5)))
    }

    @Test
    func namesNextPeriodAfterItEnds() throws {
        let food = ReviewInsight.Category(name: "食費", amount: 64200, previous: 60000, budget: 60000)
        let finished = Self.input(scale: .week, isCurrent: false, categories: [food])
        let current = Self.input(scale: .week, isCurrent: true, categories: [food])

        let after = try #require(ReviewInsight.pick(from: finished).first)
        let during = try #require(ReviewInsight.pick(from: current).first)

        #expect(after.suggestions.first == "次の週は、食費をこまめに確かめてみましょう。")
        #expect(during.suggestions.first == "残りの日は、食費をこまめに確かめてみましょう。")
    }
}

private extension ReviewInsightSuggestionTests {
    static func input(
        scale: ReviewPeriod.Scale = .month,
        isCurrent: Bool,
        categories: [ReviewInsight.Category]
    ) -> ReviewInsight.Input {
        ReviewInsight.Input(
            scale: scale,
            isCurrent: isCurrent,
            elapsedDays: isCurrent ? 18 : 30,
            totalDays: 30,
            expense: 182_400,
            previousExpense: 162_900,
            income: 0,
            hasPrevious: true,
            categories: categories,
            largestExpense: nil
        )
    }

    static func period() throws -> ReviewPeriod {
        let date = try #require(LocalDate("2026-11-18"))

        return ReviewPeriod(
            scale: .month,
            containing: date,
            monthStartDay: .first,
            weekStart: .sunday
        )
    }
}
