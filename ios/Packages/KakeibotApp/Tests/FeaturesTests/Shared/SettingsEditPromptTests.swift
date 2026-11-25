import Core
@testable import FeatureModels
import Store
import Testing

@MainActor
struct SettingsEditPromptTests {
    @Test
    func showsOnePromptAtATime() {
        var prompt = SettingsEditPrompt<Never>()

        prompt.isMenuOpen = true
        let menu = prompt.isMenuOpen

        prompt.isConfirmingDelete = true

        #expect(menu)
        #expect(!prompt.isMenuOpen)
        #expect(prompt.isConfirmingDelete)
        #expect(!prompt.isConfirmingDiscard)
        #expect(!prompt.isConfirmingHide)
        #expect(!prompt.isConfirmingHideChanges)
    }

    @Test
    func closesOnlyThePromptInFront() {
        var prompt = SettingsEditPrompt<Never>()

        prompt.isConfirmingHide = true
        prompt.isConfirmingDiscard = false
        let kept = prompt.isConfirmingHide

        prompt.isConfirmingHide = false

        #expect(kept)
        #expect(prompt == SettingsEditPrompt<Never>())
    }

    @Test
    func keepsPanelOpenBehindPrompt() throws {
        let database = try AppDatabase.inMemory()
        let model = RewardRuleEditModel(parts: .system(database))
        let closed = model.state.prompt.panel

        model.state.open(.amount)
        model.state.prompt.isConfirmingDelete = true
        let opened = model.state.prompt.panel

        model.state.closePanel()

        #expect(closed == nil)
        #expect(opened == .amount)
        #expect(model.state.prompt.panel == nil)
        #expect(model.state.prompt.isConfirmingDelete)
    }
}
