import Core

public extension SyncModel {
    struct WalletWork: Equatable, Sendable {
        public private(set) var wallet: Wallet.ID?

        public init() {}
    }
}

public extension SyncModel.WalletWork {
    func isWorking(on id: Wallet.ID) -> Bool {
        wallet == id
    }

    mutating func begin(_ id: Wallet.ID) {
        wallet = id
    }

    mutating func end(_ id: Wallet.ID) {
        if wallet == id {
            wallet = nil
        }
    }
}
