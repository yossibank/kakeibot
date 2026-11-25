import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

extension AssetsModelTests {
    @Test
    func opensRewardSheetFromItsFirstLook() async throws {
        let setup = try await Setup()
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)

        model.state.present(.reward)
        model.state.toggleGuide()
        model.state.isEditingRules = true

        let guideBefore = model.state.reward.isGuideOpen
        let rulesBefore = model.state.isEditingRules

        model.state.sheet = nil
        model.state.present(.reward)

        #expect(guideBefore)
        #expect(rulesBefore)
        #expect(model.state.sheet == .reward)
        #expect(model.state.reward.isGuideOpen == false)
        #expect(model.state.isEditingRules == false)
    }

    @Test
    func showsGoalEditorOrRulesInRewardSheet() async throws {
        let setup = try await Setup()
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)

        model.state.editGoal(nil)

        let target = model.state.goalTarget
        let rulesWhileEditing = model.state.isEditingRules

        model.state.isEditingRules = false

        let targetAfterOtherClose = model.state.goalTarget

        model.state.goalTarget = nil
        model.state.isEditingRules = true

        #expect(target != nil)
        #expect(target?.goal == nil)
        #expect(rulesWhileEditing == false)
        #expect(targetAfterOtherClose == target)
        #expect(model.state.goalTarget == nil)
        #expect(model.state.isEditingRules)
    }

    @Test
    func handsOverPendingOpeningOnce() async throws {
        let setup = try await Setup()
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)
        let id = Entry.ID()

        let empty = model.state.takePending()

        model.state.open(afterSheet: .entry(id))

        let first = model.state.takePending()
        let second = model.state.takePending()

        #expect(empty == nil)
        #expect(first == .entry(id))
        #expect(second == nil)
    }
}
