import FeatureModels
import Testing

struct ScreenOutcomeTests {
    @Test
    func startsWithoutValue() {
        let outcome = ScreenOutcome<Int>()

        #expect(outcome.value == nil)
        #expect(outcome == ScreenOutcome<Int>())
    }

    @Test
    func reportsSameValueSentTwiceAsChange() {
        var outcome = ScreenOutcome<Int>()

        outcome.send(1)
        let first = outcome
        outcome.send(1)

        #expect(first.value == 1)
        #expect(outcome.value == 1)
        #expect(outcome != first)
    }
}
