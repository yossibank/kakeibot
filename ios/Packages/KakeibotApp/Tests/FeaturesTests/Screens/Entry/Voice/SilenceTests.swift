import FeatureModels
import Foundation
import Testing

struct SilenceTests {
    @Test
    func startsAndClearsSilence() {
        let date = Date(timeIntervalSince1970: 100)
        var silence = EntryVoiceFlow.Silence()

        let before = silence.startedAt
        silence.start(at: date)
        let started = silence.startedAt
        silence.clear()

        #expect(before == nil)
        #expect(started == date)
        #expect(silence.startedAt == nil)
    }
}
