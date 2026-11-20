import Core
import Testing

struct ReviewBreakdownTests {
    @Test
    func splitsMoreVisitsAtSamePrice() throws {
        let input = Self.input(
            current: Self.spends("食費", "セブン", 12, 700) + Self.spends("食費", "いなげや", 6, 3500),
            previous: Self.spends("食費", "セブン", 8, 700) + Self.spends("食費", "いなげや", 6, 3500)
        )

        let breakdown = try #require(ReviewBreakdown.make(from: input))

        #expect(breakdown.insights.map(\.fact) == [
            "食費が、前の月の 14 回から 18 回に増えています。1 回はおよそ 1,633円 で、前の月と変わりません。",
            "食費の増えた分のうち、セブンが 2,800円 を占めています。"
        ])
        #expect(breakdown.suggestion == "次の月は、食費を 14 回ほどにすると、6,500円 ほど浮きます。")
        #expect(breakdown.summary.rows == [
            ReviewBreakdown.Row(
                name: "いなげや",
                count: 6,
                previousCount: 6,
                amount: 21000,
                previousAmount: 21000
            ),
            ReviewBreakdown.Row(
                name: "セブン",
                count: 12,
                previousCount: 8,
                amount: 8400,
                previousAmount: 5600
            )
        ])
    }

    @Test
    func splitsHigherPrice() throws {
        let input = Self.input(
            category: "外食",
            current: Self.spends("外食", nil, 4, 3000),
            previous: Self.spends("外食", nil, 4, 2000),
            isCurrent: true
        )

        let breakdown = try #require(ReviewBreakdown.make(from: input))

        #expect(breakdown.insights.map(\.fact) == [
            "外食の 1 回が、前の月のおよそ 2,000円 から 3,000円 に上がっています。回数は 4 回です。"
        ])
        #expect(breakdown.suggestion == "外食の 1 回を前の月の 2,000円 ほどに戻すと、4,000円 ほど浮きます。")
        #expect(breakdown.summary.rows.isEmpty)
    }

    @Test
    func addsFewerCategoryAsGoodPoint() throws {
        let input = Self.input(
            current: Self.spends("食費", "セブン", 12, 700) + Self.spends("外食", nil, 3, 2000),
            previous: Self.spends("食費", "セブン", 8, 700) + Self.spends("外食", nil, 6, 2000)
        )

        let breakdown = try #require(ReviewBreakdown.make(from: input))

        #expect(breakdown.insights.map(\.labeledFact).last == "良い点：外食は、前の月の 6 回から 3 回に減っています。")
        #expect(breakdown.summary.goodPoint == "外食は、前の月の 6 回から 3 回に減っています。")
    }

    @Test
    func keepsFocusAndAction() throws {
        let input = Self.input(
            current: Self.spends("食費", "セブン", 6, 800),
            previous: Self.spends("食費", "セブン", 4, 700),
            isCurrent: true
        )

        let breakdown = try #require(ReviewBreakdown.make(from: input))
        let focus = breakdown.summary.focus

        #expect(focus == ReviewBreakdown.Focus(
            name: "食費",
            count: 6,
            previousCount: 4,
            amount: 4800,
            previousAmount: 2800
        ))
        #expect(focus.countEffect == 1400)
        #expect(focus.priceEffect == 600)
        #expect(breakdown.summary.action == ReviewBreakdown.Action(
            lead: "食費を前の月と同じ 4 回ほどに戻すと",
            amount: 1600
        ))
    }

    @Test
    func treatsSmallPriceRiseAsChangeWhenItLeads() {
        let focus = ReviewBreakdown.Focus(
            name: "食費",
            count: 22,
            previousCount: 21,
            amount: 26076,
            previousAmount: 23220
        )

        #expect(focus.priceEffect > focus.countEffect)
        #expect(!focus.hasSamePrice)
    }

    @Test
    func keepsSmallPriceRiseAsSameWhenCountLeads() {
        let focus = ReviewBreakdown.Focus(
            name: "食費",
            count: 15,
            previousCount: 10,
            amount: 15750,
            previousAmount: 10000
        )

        #expect(focus.priceEffect <= focus.countEffect)
        #expect(focus.hasSamePrice)
    }

    @Test
    func describesPaceWithoutPreviousPeriod() throws {
        let input = Self.input(
            current: Self.spends("食費", "セブン", 3, 700),
            previous: [],
            hasPrevious: false
        )

        let breakdown = try #require(ReviewBreakdown.make(from: input))

        #expect(breakdown.insights.map(\.fact) == ["食費は 3 回で、1 回はおよそ 700円 です。"])
        #expect(breakdown.suggestion == nil)
        #expect(breakdown.summary.rows.map(\.previousCount) == [0])
    }

    @Test
    func groupsOnlySameMemos() throws {
        let current = Self.spends("食費", "ｾﾌﾞﾝ", 2, 700) + Self.spends("食費", " セブン ", 2, 700)
            + Self.spends("食費", "セブン 駅前", 1, 700) + Self.spends("食費", "ローソン", 1, 700)

        let input = Self.input(current: current, previous: [], hasPrevious: false)
        let breakdown = try #require(ReviewBreakdown.make(from: input))

        #expect(breakdown.summary.rows == [ReviewBreakdown.Row(
            name: "セブン",
            count: 4,
            previousCount: 0,
            amount: 2800,
            previousAmount: 0
        )])
    }

    @Test
    func skipsWhenCategoryIsSmall() {
        let input = Self.input(current: Self.spends("食費", "セブン", 2, 700), previous: [])

        #expect(ReviewBreakdown.make(from: input) == nil)
    }

    @Test
    func skipsWhenNothingChanged() {
        let spends = Self.spends("食費", "セブン", 4, 700)
        let input = Self.input(current: spends, previous: spends)

        #expect(ReviewBreakdown.make(from: input) == nil)
    }
}

private extension ReviewBreakdownTests {
    static func spends(
        _ category: String,
        _ memo: String?,
        _ count: Int,
        _ amount: Int
    ) -> [ReviewBreakdown.Spend] {
        let spend = ReviewBreakdown.Spend(category: category, memo: memo, amount: amount)
        return Array(repeating: spend, count: count)
    }

    static func input(
        category: String = "食費",
        current: [ReviewBreakdown.Spend],
        previous: [ReviewBreakdown.Spend],
        isCurrent: Bool = false,
        hasPrevious: Bool = true
    ) -> ReviewBreakdown.Input {
        ReviewBreakdown.Input(
            category: category,
            scale: .month,
            isCurrent: isCurrent,
            hasPrevious: hasPrevious,
            current: current,
            previous: previous
        )
    }
}
