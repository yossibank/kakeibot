import Core

public enum SyncZone {
    public static let own = "Kakeibot"

    static let walletZoneSQL = "'\(prefix)' || wallet_id"

    private static let prefix = "Wallet-"

    public static func wallet(_ id: Wallet.ID) -> String {
        prefix + id.description
    }

    public static func walletID(of zoneName: String) -> Wallet.ID? {
        guard zoneName.hasPrefix(prefix) else {
            return nil
        }

        return Wallet.ID(String(zoneName.dropFirst(prefix.count)))
    }
}
