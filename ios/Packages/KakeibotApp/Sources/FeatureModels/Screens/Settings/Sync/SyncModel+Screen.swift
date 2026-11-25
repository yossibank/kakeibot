import Core

public extension SyncModel {
    enum Offer: Hashable, Sendable {
        case sync
        case share(WalletShare)

        public var feature: String {
            switch self {
            case .sync: "端末間の同期"
            case .share: "家族との共有"
            }
        }
    }

    enum Asking: Hashable, Sendable {
        case leave(JoinedShare)
        case stop(WalletShare)
        case offer(Offer)

        public var leaving: JoinedShare? {
            guard case let .leave(item) = self else {
                return nil
            }

            return item
        }

        public var stopping: WalletShare? {
            guard case let .stop(item) = self else {
                return nil
            }

            return item
        }

        public var offer: Offer? {
            guard case let .offer(offer) = self else {
                return nil
            }

            return offer
        }
    }

    func askToStop(_ item: WalletShare) {
        closeOpened()

        state.ask(.stop(item))
    }
}

public extension SyncModel.State {
    func ask(_ asking: SyncModel.Asking) {
        if self.asking != asking {
            self.asking = asking
        }
    }

    func close(_ asking: SyncModel.Asking?) {
        if self.asking == asking,
           asking != nil {
            self.asking = nil
        }
    }
}
