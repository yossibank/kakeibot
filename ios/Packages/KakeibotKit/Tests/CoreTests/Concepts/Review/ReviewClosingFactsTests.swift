import Core
import Testing

struct ReviewClosingFactsTests {
    @Test
    func acceptsTheMatchingSentence() {
        let facts = Self.facts(.withinBudget, more: ["食費"], less: ["日用品"])

        #expect(facts.accepts("食費が多く、日用品が少なくなりました。", categories: Self.categories))
    }

    @Test
    func rejectsTheBudget() {
        let facts = Self.facts(.less, less: ["食費", "交通"])

        #expect(!facts.accepts("予算通りに、食費と交通が少なくなりました。", categories: Self.categories))
    }

    @Test
    func rejectsTheFlippedCategory() {
        let facts = Self.facts(.less, less: ["食費", "交通"])

        #expect(!facts.accepts("食費が少なかったですが、交通が多かったです。", categories: Self.categories))
    }

    @Test
    func rejectsNumbersAndStrayCategories() {
        let facts = Self.facts(.withinBudget, more: ["食費"])

        #expect(!facts.accepts("食費が 3 回多めでした。", categories: Self.categories))
        #expect(!facts.accepts("医療が多めでした。", categories: Self.categories))
    }

    @Test
    func opensWithTheVerdict() {
        #expect(Self.facts(.overBudget).opening(unit: "月") == "予算を超えました。")
        #expect(Self.facts(nil).opening(unit: "週") == "この週を締めました。")
    }

    @Test
    func writesTheDetail() {
        let facts = ReviewClosingFacts(
            verdict: .overBudget,
            more: ["交際", "衣服"],
            less: [],
            isGoalAchieved: false,
            recordsDaily: true
        )

        #expect(facts.detail == "いつもより多かったカテゴリ：交際、衣服\n前の一手は届きませんでした。\nほぼ毎日、記録が続きました。")
    }

    @Test
    func changesTheBasisWithTheVerdict() {
        let within = Self.facts(.withinBudget, more: ["食費"])
        let over = Self.facts(.overBudget, more: ["食費"])

        #expect(within.basis != over.basis)
    }
}

private extension ReviewClosingFactsTests {
    static let categories = ["食費", "交通", "日用品", "医療", "交際", "衣服"]

    static func facts(
        _ verdict: ReviewClosingFacts.Verdict?,
        more: [String] = [],
        less: [String] = []
    ) -> ReviewClosingFacts {
        ReviewClosingFacts(
            verdict: verdict,
            more: more,
            less: less,
            isGoalAchieved: nil,
            recordsDaily: false
        )
    }
}
