@testable import AppFeature
import Testing

struct ObservationStopTests {
    @Test
    func resumesOnlyOnceAfterStop() {
        var stop = AppModel.ObservationStop()

        let idle = stop.resume()
        stop.stop()
        let stopped = stop.isStopped
        let first = stop.resume()
        let second = stop.resume()

        #expect(!idle)
        #expect(stopped)
        #expect(first)
        #expect(!second)
        #expect(!stop.isStopped)
    }
}
