import Core

public enum SyncZone {
    public static let own = "Kakeibot"

    private static let prefix = "Wallet-"

    public static func wallet(_ id: Wallet.ID) -> String {
        prefix + id.description
    }

    public static func walletID(of zoneName: String) -> Wallet.ID? {
        guard zoneName.hasPrefix(prefix) else {
            return nil
        }

        let suffix = zoneName.dropFirst(prefix.count)
        let id = String(suffix)

        return Wallet.ID(id)
    }
}
