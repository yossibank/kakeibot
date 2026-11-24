import Store

public extension SyncStopReason {
    var message: String {
        switch self {
        case .signedOut: "iCloud からサインアウトしたため、同期が切れました"
        case .accountChanged: "iCloud のアカウントが変わったため、同期が切れました"
        case .cloudReplaced: "ほかの端末が iCloud のデータを置き換えたため、同期が切れました"
        }
    }
}
