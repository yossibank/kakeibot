import Core
import Testing

struct BuddyLineTests {
    @Test
    func asksForBudgetWithoutOne() {
        #expect(BuddyLine.budget(nil).mood == .calm)
    }

    @Test(arguments: [
        (100, BuddyMood.smile),
        (500, BuddyMood.calm),
        (800, BuddyMood.worried),
        (1000, BuddyMood.worried),
        (1001, BuddyMood.sad)
    ])
    func followsSpending(
        spent: Int,
        mood: BuddyMood
    ) throws {
        let today = try #require(LocalDate("2026-10-22"))
        let end = try #require(LocalDate("2026-10-31"))
        let usage = BudgetUsage(
            budget: 1000,
            spent: spent,
            today: today,
            periodEnd: end
        )

        #expect(BuddyLine.budget(usage).mood == mood)
    }

    @Test
    func cheersRewards() {
        let none = BuddyLine.reward(count: 0)
        let two = BuddyLine.reward(count: 2)

        #expect(none.mood == .calm)
        #expect(two.mood == .cheer)
        #expect(two.text.hasPrefix("2 つ"))
    }
}
