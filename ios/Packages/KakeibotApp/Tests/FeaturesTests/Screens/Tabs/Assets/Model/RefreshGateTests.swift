import FeatureModels
import Testing

struct RefreshGateTests {
    @Test
    func runsOnceMoreForRequestsWhileRunning() {
        var gate = AssetsModel.RefreshGate()

        let started = gate.request()
        let first = gate.next()
        let startedAgain = gate.request()
        let second = gate.next()
        let third = gate.next()

        #expect(started)
        #expect(first)
        #expect(!startedAgain)
        #expect(second)
        #expect(!third)
        #expect(!gate.isRunning)
    }

    @Test
    func startsAgainAfterStopping() {
        var gate = AssetsModel.RefreshGate()

        _ = gate.request()
        _ = gate.next()
        _ = gate.next()
        let started = gate.request()

        #expect(started)
        #expect(gate.isRunning)
    }
}
