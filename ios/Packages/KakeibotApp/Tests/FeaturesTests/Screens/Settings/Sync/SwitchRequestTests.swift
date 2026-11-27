import FeatureModels
import Testing

struct SwitchRequestTests {
    @Test
    func holdsAskedValueUntilCleared() {
        var request = SyncModel.SwitchRequest()

        let empty = request.isPending
        request.ask(true)
        let asked = request.isOn
        let pending = request.isPending
        request.clear()

        #expect(!empty)
        #expect(asked == true)
        #expect(pending)
        #expect(request.isOn == nil)
        #expect(!request.isPending)
    }
}
