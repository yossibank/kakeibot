import FeatureModels
import Testing

struct SettingsMenuValueChoiceTests {
    @Test
    func showsPendingValueUntilItsSaveEnds() {
        var choice = SettingsMenuValueModel<Int>.Choice()

        let empty = choice.value(over: 1)
        choice.begin(2)
        choice.begin(3)
        choice.end(2)
        let kept = choice.value(over: 1)
        choice.end(3)

        #expect(empty == 1)
        #expect(kept == 3)
        #expect(choice.pending == nil)
        #expect(choice.value(over: 1) == 1)
    }
}
