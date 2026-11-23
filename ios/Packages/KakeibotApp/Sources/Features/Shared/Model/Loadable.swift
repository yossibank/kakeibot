enum Loadable<Value> {
    case loading
    case loaded(Value)
    case failed

    var value: Value? {
        switch self {
        case let .loaded(value): value
        case .loading, .failed: nil
        }
    }

    var isLoaded: Bool {
        value != nil
    }

    var isFailed: Bool {
        switch self {
        case .failed: true
        case .loading, .loaded: false
        }
    }
}

extension Loadable: Equatable where Value: Equatable {}
extension Loadable: Sendable where Value: Sendable {}
