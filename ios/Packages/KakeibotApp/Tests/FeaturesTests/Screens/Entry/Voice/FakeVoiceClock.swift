@testable import FeatureModels
import Foundation
import Observation
import Synchronization

@MainActor
@Observable
final class FakeVoiceClock {
    private(set) var sleepers: [Int: Sleeper] = [:]

    @ObservationIgnored private var nextId = 0

    private nonisolated let time = Mutex(Date(timeIntervalSince1970: 1_791_000_000))
}

extension FakeVoiceClock {
    struct Sleeper {
        let deadline: Date
        let continuation: CheckedContinuation<Void, Never>
    }
}

extension FakeVoiceClock {
    nonisolated var screenClock: ScreenClock {
        ScreenClock {
            self.time.withLock { $0 }
        }
    }

    var isSleeping: Bool {
        !sleepers.isEmpty
    }

    func sleep(for duration: Duration) async throws {
        let id = nextId
        let deadline = screenClock.now.addingTimeInterval(duration / .seconds(1))

        nextId += 1

        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                sleepers[id] = Sleeper(deadline: deadline, continuation: continuation)
            }
        } onCancel: {
            Task { @MainActor in
                self.wake(id)
            }
        }

        try Task.checkCancellation()
    }

    func advance(by duration: Duration) {
        let now = time.withLock { time in
            time = time.addingTimeInterval(duration / .seconds(1))
            return time
        }

        for (id, sleeper) in sleepers where sleeper.deadline <= now {
            wake(id)
        }
    }
}

private extension FakeVoiceClock {
    func wake(_ id: Int) {
        sleepers.removeValue(forKey: id)?.continuation.resume()
    }
}
