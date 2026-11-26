import FeatureModels
import Observation

@MainActor
@Observable
final class ManualWait {
    private(set) var sleepers: [Int: Sleeper] = [:]

    @ObservationIgnored private var nextId = 0
    @ObservationIgnored private var time = Duration.zero
}

extension ManualWait {
    struct Sleeper {
        let deadline: Duration
        let continuation: CheckedContinuation<Void, Never>
    }
}

extension ManualWait {
    nonisolated var wait: ScreenWait {
        ScreenWait { duration in
            try await self.sleep(for: duration)
        }
    }

    var isSleeping: Bool {
        !sleepers.isEmpty
    }

    var deadlines: [Duration] {
        sleepers.values.map(\.deadline)
    }

    func sleep(for duration: Duration) async throws {
        let id = nextId
        let deadline = time + duration

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
        time += duration

        for (id, sleeper) in sleepers where sleeper.deadline <= time {
            wake(id)
        }
    }
}

private extension ManualWait {
    func wake(_ id: Int) {
        sleepers.removeValue(forKey: id)?.continuation.resume()
    }
}
