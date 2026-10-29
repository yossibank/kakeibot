import Core
import Foundation
import Store
import Testing

struct RewardGoalWriteTests {
    @Test
    func savesAndEditsGoal() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 0)
        let shoes = RewardGoalDraft(name: " 新しい靴 ", targetAmount: 8000)
        let renamed = RewardGoalDraft(name: "靴", targetAmount: 6000)

        let goal = try await database.saveRewardGoal(shoes, at: now)
        let edited = try await database.saveRewardGoal(renamed, editing: goal.id, at: now)
        let bank = try await database.rewardBank()

        #expect(goal.name == "新しい靴")
        #expect(bank.waitingGoals == [edited])
        #expect(edited.targetAmount == 6000)
    }

    @Test
    func rejectsGoalWithoutName() async throws {
        let database = try AppDatabase.inMemory()
        let draft = RewardGoalDraft(name: " ", targetAmount: 8000)

        await #expect(throws: DraftProblem.emptyName) {
            try await database.saveRewardGoal(draft, at: Date())
        }
    }

    @Test
    func buysAndUndoesGoal() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 0)
        let draft = RewardGoalDraft(name: "靴", targetAmount: 600)
        let goal = try await database.saveRewardGoal(draft, at: now)
        try await database.saveSavings(600, at: now)

        try await database.setRewardGoalPurchased(goal.id, isPurchased: true, at: now)
        let bought = try await database.rewardBank()
        try await database.setRewardGoalPurchased(goal.id, isPurchased: false, at: now)
        let undone = try await database.rewardBank()

        #expect(bought.boughtGoals.map(\.id) == [goal.id])
        #expect(bought.balance == 0)
        #expect(undone.waitingGoals.map(\.id) == [goal.id])
        #expect(undone.balance == 600)
    }

    @Test
    func rejectsBuyingWithShortBalance() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 0)
        let draft = RewardGoalDraft(name: "靴", targetAmount: 600)
        let goal = try await database.saveRewardGoal(draft, at: now)
        try await database.saveSavings(500, at: now)

        await #expect(throws: AppDatabase.RewardGoalWriteError.shortOfBalance) {
            try await database.setRewardGoalPurchased(goal.id, isPurchased: true, at: now)
        }

        let bank = try await database.rewardBank()

        #expect(bank.waitingGoals.map(\.id) == [goal.id])
        #expect(bank.balance == 500)
    }

    @Test
    func deletesGoal() async throws {
        let database = try AppDatabase.inMemory()
        let draft = RewardGoalDraft(name: "靴", targetAmount: 600)
        let goal = try await database.saveRewardGoal(draft, at: Date())

        try await database.deleteRewardGoal(goal.id)
        let bank = try await database.rewardBank()

        #expect(bank.goals.isEmpty)
    }
}

private extension AppDatabase {
    func saveSavings(
        _ amount: Int,
        at now: Date
    ) async throws {
        let icon = IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")
        let draft = RewardRuleDraft(name: "自炊した日", amount: amount, icon: icon)
        let rule = try await saveRewardRule(draft, at: now)
        let date = try #require(LocalDate("2026-10-22"))

        try await setReward(rule.id, isAchieved: true, on: date, at: now)
    }
}
