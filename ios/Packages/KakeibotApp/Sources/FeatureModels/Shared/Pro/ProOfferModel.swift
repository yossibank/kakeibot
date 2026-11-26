import Observation

@MainActor
@Observable
public final class ProOfferModel {
    public let state = State()

    public init() {}
}

public extension ProOfferModel {
    enum Presented: Hashable, Sendable {
        case pro
    }

    @MainActor
    @Observable
    final class State {
        public var presented = Shown<Presented>()
    }
}

public extension ProOfferModel {
    func showPro() {
        state.presented.show(.pro)
    }

    func closePro() {
        guard state.presented.isShowing(.pro) else {
            return
        }

        state.presented.close(.pro)
    }
}
