import Core

extension Wallet.Kind {
    var title: String {
        switch self {
        case .cash: "現金"
        case .bank: "銀行"
        case .card: "カード"
        case .emoney: "電子マネー"
        case .point: "ポイント"
        case .other: "その他"
        }
    }
}
