import Core

public extension SyncModel {
    enum Offer: Hashable, Sendable {
        case sync
        case share(WalletShare)
    }

    enum Presented: Hashable, Sendable {
        case choice(SyncChoice)
        case invitation(WalletShare)
        case opened(WalletShare)
        case leave(JoinedShare)
        case stop(WalletShare)
        case offer(Offer)
    }
}

public extension SyncModel {
    func askToStop(_ item: WalletShare) {
        closeOpened()
        state.presented.show(.stop(item))
    }
}

public extension SyncModel.Presented {
    var choice: SyncChoice? {
        guard case let .choice(choice) = self else {
            return nil
        }

        return choice
    }

    var invitation: WalletShare? {
        guard case let .invitation(item) = self else {
            return nil
        }

        return item
    }

    var opened: WalletShare? {
        guard case let .opened(item) = self else {
            return nil
        }

        return item
    }

    var leaving: JoinedShare? {
        guard case let .leave(item) = self else {
            return nil
        }

        return item
    }

    var stopping: WalletShare? {
        guard case let .stop(item) = self else {
            return nil
        }

        return item
    }

    var offer: SyncModel.Offer? {
        guard case let .offer(offer) = self else {
            return nil
        }

        return offer
    }
}

public extension SyncModel.Offer {
    var feature: String {
        switch self {
        case .sync: "端末間の同期"
        case .share: "家族との共有"
        }
    }
}

extension SyncModel.State {
    func closeChoice() {
        if let choice = presented.current?.choice {
            presented.close(.choice(choice))
        }
    }
}
