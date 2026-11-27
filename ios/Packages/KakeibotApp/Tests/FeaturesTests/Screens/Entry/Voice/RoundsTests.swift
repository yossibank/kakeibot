import FeatureModels
import Testing

struct RoundsTests {
    @Test
    func countsStartsAndEndsApart() {
        var rounds = EntryVoiceFlow.Rounds()

        rounds.start()
        rounds.end()
        rounds.end()

        #expect(rounds.starts == 1)
        #expect(rounds.ends == 2)
    }
}
