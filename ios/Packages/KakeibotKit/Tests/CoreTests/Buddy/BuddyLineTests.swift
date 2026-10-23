import Core
import Testing

struct BuddyLineTests {
    @Test
    func asksForBudgetWithoutOne() {
        #expect(BuddyLine.budget(nil).text.hasPrefix("予算を決めると"))
    }

    @Test(arguments: [
        (100, "いい調子です"),
        (500, "半分を過ぎました"),
        (800, "予算まであと少しです"),
        (1000, "予算まであと少しです"),
        (1001, "予算を超えました")
    ])
    func followsSpending(
        spent: Int,
        opening: String
    ) throws {
        let today = try #require(LocalDate("2026-10-22"))
        let end = try #require(LocalDate("2026-10-31"))
        let usage = BudgetUsage(
            budget: 1000,
            spent: spent,
            today: today,
            periodEnd: end
        )

        #expect(BuddyLine.budget(usage).text.hasPrefix(opening))
    }

    @Test
    func cheersRewards() {
        let none = BuddyLine.reward(count: 0)
        let one = BuddyLine.reward(count: 1)
        let two = BuddyLine.reward(count: 2)

        #expect(none.text.hasPrefix("できたことがあれば"))
        #expect(one.text.hasPrefix("達成しました"))
        #expect(two.text.hasPrefix("2 つ"))
    }
}
