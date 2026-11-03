import Observation
import Synchronization
import Testing

public enum ObservationWait {}

@MainActor
public extension ObservationWait {
    static func until(
        timeout: Duration = .seconds(30),
        sourceLocation: SourceLocation = #_sourceLocation,
        _ isReady: @escaping @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock.now.advanced(by: timeout)

        while !isReady() {
            guard await nextChange(of: isReady, before: deadline) == .changed else {
                Issue.record(
                    "\(timeout) 待っても変化の知らせが届かなかった",
                    sourceLocation: sourceLocation
                )

                return
            }
        }
    }
}

@MainActor
private extension ObservationWait {
    enum Wake {
        case changed
        case timedOut
    }

    static func nextChange(
        of read: @escaping @MainActor () -> Bool,
        before deadline: ContinuousClock.Instant
    ) async -> Wake {
        let signal = ChangeSignal()

        let timer = Task {
            try? await Task.sleep(until: deadline, clock: .continuous)
            signal.fire(.timedOut)
        }

        let wake = await withCheckedContinuation { continuation in
            signal.wait(continuation)

            withObservationTracking {
                _ = read()
            } onChange: {
                signal.fire(.changed)
            }
        }

        timer.cancel()

        return wake
    }
}

private final class ChangeSignal: Sendable {
    private let state = Mutex<State>(.idle)
}

private extension ChangeSignal {
    enum State {
        case idle
        case waiting(CheckedContinuation<ObservationWait.Wake, Never>)
        case fired(ObservationWait.Wake)
    }

    func wait(_ continuation: CheckedContinuation<ObservationWait.Wake, Never>) {
        state.withLock { state in
            if case let .fired(wake) = state {
                continuation.resume(returning: wake)
            } else {
                state = .waiting(continuation)
            }
        }
    }

    func fire(_ wake: ObservationWait.Wake) {
        state.withLock { state in
            switch state {
            case .idle:
                state = .fired(wake)

            case let .waiting(continuation):
                continuation.resume(returning: wake)
                state = .fired(wake)

            case .fired:
                break
            }
        }
    }
}
