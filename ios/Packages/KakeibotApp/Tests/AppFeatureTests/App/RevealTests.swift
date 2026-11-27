@testable import AppFeature
import Testing

struct RevealTests {
    @Test
    func movesCurtainAndRemembersSweepAndHomeLoad() {
        var reveal = AppModel.Reveal()

        let before = reveal
        reveal.finishSweep()
        reveal.markHomeLoaded()
        reveal.leaveCurtain()
        let leaving = reveal.curtain
        reveal.finishCurtain()

        #expect(before.curtain == .covering)
        #expect(!before.hasSwept && !before.isHomeLoaded)
        #expect(reveal.hasSwept && reveal.isHomeLoaded)
        #expect(leaving == .leaving)
        #expect(reveal.curtain == .finished)
    }
}
