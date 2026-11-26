import Observation

@MainActor
@Observable
public final class ProOfferModel {
    public let state = State()

    public init() {}
}

public extension ProOfferModel {
    @MainActor
    @Observable
    final class State {
        public var isShowingPro = false
    }
}

public extension ProOfferModel {
    func showPro() {
        state.isShowingPro = true
    }

    func closePro() {
        guard state.isShowingPro else {
            return
        }

        state.isShowingPro = false
    }
}
