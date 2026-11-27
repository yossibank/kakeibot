import Observation

@MainActor
@Observable
public final class ProOfferModel {
    public let state = State()

    public init() {}
}

public extension ProOfferModel {
    enum Destination: Hashable, Sendable {
        case pro
    }

    struct Presented: ScreenEditable {
        public var destination = Shown<Destination>()
    }

    @MainActor
    @Observable
    final class State {
        public var presented = Presented()
    }
}

public extension ProOfferModel {
    func showPro() {
        state.presented.destination.show(.pro)
    }

    func closePro() {
        guard state.presented.destination.isShowing(.pro) else {
            return
        }

        state.presented.destination.close(.pro)
    }
}
