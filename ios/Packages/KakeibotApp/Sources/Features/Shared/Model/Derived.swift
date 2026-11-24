import Observation

@MainActor
@Observable
final class Derived<Value> {
    @ObservationIgnored private var cached: Value?

    @ObservationIgnored private let onInvalidate: (() -> Void)?

    private var stamp = 0

    init(onInvalidate: (() -> Void)? = nil) {
        self.onInvalidate = onInvalidate
    }
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
        onInvalidate?()
    }
}
