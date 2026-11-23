import Observation

@MainActor
@Observable
final class Derived<Value> {
    @ObservationIgnored private var cached: Value?

    private var stamp = 0
}

extension Derived {
    func value(_ make: () -> Value) -> Value {
        _ = stamp

        if let cached {
            return cached
        }

        let made = withObservationTracking(make) { [weak self] in
            MainActor.assumeIsolated {
                self?.invalidate()
            }
        }

        cached = made

        return made
    }
}

private extension Derived {
    func invalidate() {
        cached = nil
        stamp &+= 1
    }
}
