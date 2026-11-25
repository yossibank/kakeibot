import FeatureModels
import Testing

struct ForegroundReturnTests {
    @Test
    func detectsForegroundAfterInactive() {
        var foreground = ForegroundReturn()

        let results = [
            foreground.receive(.inactive),
            foreground.receive(.active),
            foreground.receive(.background),
            foreground.receive(.inactive),
            foreground.receive(.active),
            foreground.receive(.active)
        ]

        #expect(results == [false, false, false, false, true, false])
    }
}
