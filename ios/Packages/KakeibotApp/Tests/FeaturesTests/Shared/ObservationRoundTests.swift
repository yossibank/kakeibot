@testable import FeatureModels
import Observation
import Testing
import TestSupport

@MainActor
struct ObservationRoundTests {
    @Test
    func observesAgainWhenRestarted() async {
        let round = ObservationRound()
        let counter = Counter()

        let task = Task {
            await round.each([{ await counter.hold() }])
        }

        await ObservationWait.until { counter.started == 1 }
        round.restart()
        await ObservationWait.until { counter.started == 2 && counter.stopped == 1 }
        let stopped = counter.stopped
        task.cancel()

        #expect(round.count == 1)
        #expect(stopped == 1)
    }

    @Test
    func restartsEveryModelSharingRound() async {
        let round = ObservationRound()
        let first = Counter()
        let second = Counter()

        let task = Task {
            await round.each([
                { await first.hold() },
                { await second.hold() }
            ])
        }

        await ObservationWait.until { first.started == 1 && second.started == 1 }
        round.restart()
        await ObservationWait.until { first.started == 2 && second.started == 2 }
        task.cancel()

        #expect(first.stopped >= 1)
        #expect(second.stopped >= 1)
    }
}

extension ObservationRoundTests {
    @MainActor
    @Observable
    final class Counter {
        var started = 0
        var stopped = 0

        func hold() async {
            started += 1
            try? await Task.sleep(for: .seconds(3600))
            stopped += 1
        }
    }
}
