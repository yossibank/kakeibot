import Core
import Testing

struct ReviewInsightTests {
    @Test
    func findsBudgetPaceWithDailyAmount() {
        let food = ReviewInsight.Category(name: "食費", amount: 58200, previous: 49300, budget: 60000)
        let input = Self.input(elapsedDays: 18, categories: [food])

        let insights = ReviewInsight.pick(from: input)

        #expect(insights.first?.kind == .budgetPace)
        #expect(insights.first?.fact.contains("予算の 97%") == true)
        #expect(insights.first?.fact.contains("残りの 12 日を 1 日 150円") == true)
    }

    @Test
    func ranksOverBudgetFirst() {
        let food = ReviewInsight.Category(name: "食費", amount: 64200, previous: 60000, budget: 60000)
        let fun = ReviewInsight.Category(name: "交際費", amount: 21000, previous: 8000, budget: nil)
        let input = Self.input(elapsedDays: 29, categories: [fun, food])

        let insights = ReviewInsight.pick(from: input)

        #expect(insights.map(\.kind) == [.overBudget, .increase])
        #expect(insights.first?.fact == "食費は、予算の 60,000円 を 4,200円 超えています。")
    }

    @Test
    func pairsConcernWithGoodNews() {
        let fun = ReviewInsight.Category(name: "交際費", amount: 21000, previous: 8000, budget: nil)
        let train = ReviewInsight.Category(name: "交通", amount: 21800, previous: 26100, budget: nil)
        let big = ReviewInsight.Expense(categoryName: "家電", amount: 48000)
        let input = Self.input(elapsedDays: 30, categories: [fun, train], largestExpense: big)

        let insights = ReviewInsight.pick(from: input)

        #expect(insights.map(\.kind) == [.increase, .decrease])
    }

    @Test
    func findsSurplusOnlyAfterPeriodEnds() {
        let current = Self.input(elapsedDays: 10, income: 265_000)
        let finished = Self.input(isCurrent: false, elapsedDays: 30, income: 265_000)

        let during = ReviewInsight.pick(from: current)
        let after = ReviewInsight.pick(from: finished)

        #expect(during.map(\.kind) == [.total])
        #expect(after.first?.kind == .surplus)
        #expect(after.first?.fact == "収入の 265,000円 から、82,600円 残せました。")
    }

    @Test
    func findsDeficit() {
        let input = Self.input(elapsedDays: 20, income: 150_000)

        let insights = ReviewInsight.pick(from: input)

        #expect(insights.first?.kind == .deficit)
    }

    @Test
    func fallsBackToTotal() {
        let input = Self.input(elapsedDays: 10)

        let insights = ReviewInsight.pick(from: input)

        #expect(insights.map(\.fact) == ["支出は 182,400円 です。前の月より 19,500円 多いです。"])
    }

    @Test
    func namesPeriodByScale() {
        let train = ReviewInsight.Category(name: "交通", amount: 21800, previous: 26100, budget: nil)
        let input = Self.input(scale: .week, elapsedDays: 7, categories: [train])

        let insights = ReviewInsight.pick(from: input)

        #expect(insights.first?.fact == "交通が、前の週の 26,100円 から 21,800円 に減っています（16% 減）。")
    }

    @Test
    func labelsFactsByDirection() {
        let fun = ReviewInsight.Category(name: "交際費", amount: 21000, previous: 8000, budget: nil)
        let train = ReviewInsight.Category(name: "交通", amount: 21800, previous: 26100, budget: nil)
        let input = Self.input(elapsedDays: 30, categories: [fun, train])

        let labels = ReviewInsight.pick(from: input)
            .map { $0.labeledFact.components(separatedBy: "：").first }
        let total = ReviewInsight.pick(from: Self.input(elapsedDays: 10))

        #expect(labels == ["気を付けたい点", "良い点"])
        #expect(total.first?.labeledFact.hasPrefix("事実：") == true)
    }
}

private extension ReviewInsightTests {
    static func input(
        scale: ReviewPeriod.Scale = .month,
        isCurrent: Bool = true,
        elapsedDays: Int,
        income: Int = 0,
        categories: [ReviewInsight.Category] = [],
        largestExpense: ReviewInsight.Expense? = nil
    ) -> ReviewInsight.Input {
        ReviewInsight.Input(
            scale: scale,
            isCurrent: isCurrent,
            elapsedDays: elapsedDays,
            totalDays: 30,
            expense: 182_400,
            previousExpense: 162_900,
            income: income,
            hasPrevious: true,
            categories: categories,
            largestExpense: largestExpense
        )
    }
}
