import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

@MainActor
struct AssetsRewardGoalEditModelTests {
    @Test
    func newGoalIsChangedAfterInput() throws {
        let database = try AppDatabase.inMemory()
        let model = AssetsRewardGoalEditModel(parts: .system(database))

        let changedBeforeInput = model.flow.output.isChanged

        model.state.fields.name = "新しい靴"

        #expect(!changedBeforeInput)
        #expect(model.flow.output.isChanged)
    }

    @Test
    func opensAmountPanelOnlyForNewGoal() throws {
        let database = try AppDatabase.inMemory()

        let goal = RewardGoal(
            name: "新しい靴",
            targetAmount: 12000,
            createdAt: Date(),
            updatedAt: Date()
        )

        let adding = AssetsRewardGoalEditModel(parts: .system(database))
        let editing = AssetsRewardGoalEditModel(parts: .system(database), editing: goal)

        let panelWhenAdding = adding.state.presented.panel.current
        let panelWhenEditing = editing.state.presented.panel.current

        adding.state.presented.panel.closeAll()
        editing.state.presented.panel.show(.amount)

        #expect(panelWhenAdding == .amount)
        #expect(panelWhenEditing == nil)
        #expect(adding.state.presented.panel.current == nil)
        #expect(editing.state.presented.panel.current == .amount)
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

        let model = AssetsRewardGoalEditModel(parts: .system(database), editing: goal)

        let changedBeforeEdit = model.flow.output.isChanged

        model.state.press(.digit(5))
        let changedAfterEdit = model.flow.output.isChanged

        #expect(!changedBeforeEdit)
        #expect(changedAfterEdit)
    }

    @Test
    func savesNewGoal() async throws {
        let database = try AppDatabase.inMemory()
        let model = AssetsRewardGoalEditModel(parts: .system(database))
        model.state.fields.name = "新しい靴"
        model.state.press(.digit(5))
        model.state.press(.doubleZero)

        let isSaved = await model.save() != nil
        let goals = try await database.rewardBank().waitingGoals

        #expect(isSaved)
        #expect(goals.map(\.name) == ["新しい靴"])
        #expect(goals.map(\.targetAmount) == [500])
    }

    @Test
    func tellsWhenGoalCannotBeSaved() async throws {
        let database = try AppDatabase.inMemory()
        let model = AssetsRewardGoalEditModel(parts: .system(database))
        model.state.fields.name = "新しい靴"
        model.state.press(.digit(5))
        try await database.failWrites(to: "reward_goal")

        let isSaved = await model.save() != nil

        #expect(!isSaved)
        #expect(model.state.notices.error.message == "目標を保存できませんでした")
    }

    @Test
    func deletesEditedGoal() async throws {
        let database = try AppDatabase.inMemory()
        let draft = RewardGoalDraft(name: "新しい靴", targetAmount: 12000)
        let goal = try await database.saveRewardGoal(draft, at: Date())
        let model = AssetsRewardGoalEditModel(parts: .system(database), editing: goal)

        await model.flow.delete().value
        let goals = try await database.rewardBank().waitingGoals

        #expect(model.flow.state.outcome.value?.closes == true)
        #expect(goals.isEmpty)
    }

    @Test
    func tellsWhenGoalCannotBeDeleted() async throws {
        let database = try AppDatabase.inMemory()
        let draft = RewardGoalDraft(name: "新しい靴", targetAmount: 12000)
        let goal = try await database.saveRewardGoal(draft, at: Date())
        let model = AssetsRewardGoalEditModel(parts: .system(database), editing: goal)
        let adding = AssetsRewardGoalEditModel(parts: .system(database))
        try await database.failWrites(to: "reward_goal")

        await model.flow.delete().value
        await adding.flow.delete().value

        #expect(model.flow.state.outcome.value == nil)
        #expect(adding.flow.state.outcome.value == nil)
        #expect(model.state.notices.error.message == "目標を削除できませんでした")
        #expect(adding.state.notices.error.message == nil)
    }
}
