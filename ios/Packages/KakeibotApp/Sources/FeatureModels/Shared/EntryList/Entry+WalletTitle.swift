import Core

extension Entry.Kind {
    var walletTitle: String {
        switch self {
        case .expense: "支払い元"
        case .income: "入金先"
        case .transfer: "振替元"
        }
    }
}
