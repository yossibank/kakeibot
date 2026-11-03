import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct AssetsGoalEditModelTests {
    @Test
    func newGoalIsChangedAfterInput() throws {
        let database = try AppDatabase.inMemory()
        let model = AssetsGoalEditModel(database: database)

        let changedBeforeInput = model.isChanged

        model.name = "新しい靴"

        #expect(!changedBeforeInput)
        #expect(model.isChanged)
    }

    @Test
    func editingGoalIsChangedOnlyWhenDraftDiffers() throws {
        let database = try AppDatabase.inMemory()

        let goal = RewardGoal(
            name: "新しい靴",
            targetAmount: 12000,
            createdAt: Date(),
            updatedAt: Date()
        )

        let model = AssetsGoalEditModel(database: database, editing: goal)

        let changedBeforeEdit = model.isChanged

        model.press(.digit(5))
        let changedAfterEdit = model.isChanged

        #expect(!changedBeforeEdit)
        #expect(changedAfterEdit)
    }

    @Test
    func savesNewGoal() async throws {
        let database = try AppDatabase.inMemory()
        let model = AssetsGoalEditModel(database: database)
        model.name = "新しい靴"
        model.press(.digit(5))
        model.press(.doubleZero)

        let isSaved = await model.save()
        let goals = try await database.rewardBank().waitingGoals

        #expect(isSaved)
        #expect(goals.map(\.name) == ["新しい靴"])
        #expect(goals.map(\.targetAmount) == [500])
    }

    @Test
    func tellsWhenGoalCannotBeSaved() async throws {
        let database = try AppDatabase.inMemory()
        let model = AssetsGoalEditModel(database: database)
        model.name = "新しい靴"
        model.press(.digit(5))
        try await database.failWrites(to: "reward_goal")

        let isSaved = await model.save()

        #expect(isSaved == false)
        #expect(model.errorNotice.message == "目標を保存できませんでした")
    }

    @Test
    func deletesEditedGoal() async throws {
        let database = try AppDatabase.inMemory()
        let draft = RewardGoalDraft(name: "新しい靴", targetAmount: 12000)
        let goal = try await database.saveRewardGoal(draft, at: Date())
        let model = AssetsGoalEditModel(database: database, editing: goal)

        let isDeleted = await model.delete()
        let goals = try await database.rewardBank().waitingGoals

        #expect(isDeleted)
        #expect(goals.isEmpty)
    }

    @Test
    func tellsWhenGoalCannotBeDeleted() async throws {
        let database = try AppDatabase.inMemory()
        let draft = RewardGoalDraft(name: "新しい靴", targetAmount: 12000)
        let goal = try await database.saveRewardGoal(draft, at: Date())
        let model = AssetsGoalEditModel(database: database, editing: goal)
        let adding = AssetsGoalEditModel(database: database)
        try await database.failWrites(to: "reward_goal")

        let isDeleted = await model.delete()
        let isNewDeleted = await adding.delete()

        #expect(isDeleted == false)
        #expect(isNewDeleted == false)
        #expect(model.errorNotice.message == "目標を削除できませんでした")
        #expect(adding.errorNotice.message == nil)
    }
}
