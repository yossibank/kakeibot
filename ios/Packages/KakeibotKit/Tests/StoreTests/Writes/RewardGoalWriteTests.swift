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

        let goal = try await database.saveRewardGoal(shoes, at: now)

        let edited = try await database.saveRewardGoal(
            RewardGoalDraft(name: "靴", targetAmount: 6000),
            editing: goal.id,
            at: now
        )

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

        try await database.setRewardGoalPurchased(
            goal.id,
            isPurchased: true,
            at: now
        )
        let bought = try await database.rewardBank()

        try await database.setRewardGoalPurchased(
            goal.id,
            isPurchased: false,
            at: now
        )
        let undone = try await database.rewardBank()

        #expect(bought.boughtGoals.map(\.id) == [goal.id])
        #expect(bought.balance == -600)
        #expect(undone.waitingGoals.map(\.id) == [goal.id])
        #expect(undone.balance == 0)
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
