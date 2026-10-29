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
}
