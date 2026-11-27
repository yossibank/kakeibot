import Core

public extension WalletEditModel {
    struct BalanceSign: Equatable, Sendable {
        public private(set) var isNegative: Bool

        public init(isNegative: Bool) {
            self.isNegative = isNegative
        }
    }
}

public extension WalletEditModel.BalanceSign {
    mutating func set(_ isNegative: Bool) {
        self.isNegative = isNegative
    }

    mutating func follow(from oldKind: Wallet.Kind, to kind: Wallet.Kind) {
        if isNegative == oldKind.isDebt {
            isNegative = kind.isDebt
        }
    }
}
