import Observation

@MainActor
@Observable
public final class ObservationRound {
    public private(set) var count = 0

    @ObservationIgnored private var waiting: [Int: CheckedContinuation<Void, Never>] = [:]
    @ObservationIgnored private var nextId = 0

    public init() {}
}

public extension ObservationRound {
    func restart() {
        count += 1

        let woken = waiting

        waiting = [:]

        for continuation in woken.values {
            continuation.resume()
        }
    }

    func each(_ observations: [@MainActor @Sendable () async -> Void]) async {
        while !Task.isCancelled {
            await withDiscardingTaskGroup { group in
                group.addTask {
                    await ScreenObservation.all(observations)
                }

                await nextRound()
                group.cancelAll()
            }
        }
    }
}

private extension ObservationRound {
    func nextRound() async {
        let id = nextId

        nextId += 1

        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume()
                } else {
                    waiting[id] = continuation
                }
            }
        } onCancel: {
            Task { @MainActor in
                self.wake(id)
            }
        }
    }

    func wake(_ id: Int) {
        waiting.removeValue(forKey: id)?.resume()
    }
}
