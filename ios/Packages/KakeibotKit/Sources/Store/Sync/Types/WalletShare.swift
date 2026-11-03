import Core

public struct WalletShare: Hashable, Sendable {
    public let wallet: Wallet
    public let icon: Icon?
    public let isShared: Bool

    public init(
        wallet: Wallet,
        icon: Icon?,
        isShared: Bool
    ) {
        self.wallet = wallet
        self.icon = icon
        self.isShared = isShared
    }
}

public struct JoinedShare: Hashable, Sendable {
    public let wallet: Wallet
    public let icon: Icon?
    public let ownerName: String

    public init(
        wallet: Wallet,
        icon: Icon?,
        ownerName: String
    ) {
        self.wallet = wallet
        self.icon = icon
        self.ownerName = ownerName
    }
}
