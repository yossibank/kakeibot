import Observation
import Synchronization
import Testing

public enum ObservationWait {}

@MainActor
public extension ObservationWait {
    static func until(
        timeout: Duration = .seconds(10),
        sourceLocation: SourceLocation = #_sourceLocation,
        _ isReady: @escaping @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock.now.advanced(by: timeout)

        while !isReady() {
            guard ContinuousClock.now < deadline else {
                Issue.record(
                    "\(timeout) 待っても条件を満たさなかった",
                    sourceLocation: sourceLocation
                )

                return
            }

            await nextChange(of: isReady, before: deadline)
        }
    }
}

@MainActor
private extension ObservationWait {
    static func nextChange(
        of read: @escaping @MainActor () -> Bool,
        before deadline: ContinuousClock.Instant
    ) async {
        let signal = ChangeSignal()

        let timer = Task {
            try? await Task.sleep(until: deadline, clock: .continuous)
            signal.fire()
        }

        await withCheckedContinuation { continuation in
            signal.wait(continuation)

            withObservationTracking {
                _ = read()
            } onChange: {
                signal.fire()
            }
        }

        timer.cancel()
    }
}

private final class ChangeSignal: Sendable {
    private let state = Mutex<State>(.idle)
}

private extension ChangeSignal {
    enum State {
        case idle
        case waiting(CheckedContinuation<Void, Never>)
        case fired
    }

    func wait(_ continuation: CheckedContinuation<Void, Never>) {
        state.withLock { state in
            if case .fired = state {
                continuation.resume()
            } else {
                state = .waiting(continuation)
            }
        }
    }

    func fire() {
        state.withLock { state in
            if case let .waiting(continuation) = state {
                continuation.resume()
            }

            state = .fired
        }
    }
}
