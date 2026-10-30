import Core

extension ReviewKind {
    var entryType: Entry.Kind? {
        switch self {
        case .expense: .expense
        case .income: .income
        case .balance: nil
        }
    }
}
