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
        model.state.presented.rewardChild.show(.rules)

        let guideBefore = model.state.presented.reward.isGuideOpen
        let rulesBefore = model.state.isEditingRules

        model.state.presented.sheet.closeAll()
        model.state.present(.reward)

        #expect(guideBefore)
        #expect(rulesBefore)
        #expect(model.state.presented.sheet.current == .reward)
        #expect(model.state.presented.reward.isGuideOpen == false)
        #expect(model.state.isEditingRules == false)
    }

    @Test
    func showsGoalEditorOrRulesInRewardSheet() async throws {
        let setup = try await Setup()
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)

        model.state.editGoal(nil)

        let target = model.state.goalTarget
        let rulesWhileEditing = model.state.isEditingRules

        model.state.presented.rewardChild.close(.rules)

        let targetAfterOtherClose = model.state.goalTarget

        model.state.presented.rewardChild.goal = nil
        model.state.presented.rewardChild.show(.rules)

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
