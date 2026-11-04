public extension Entry.Kind {
    var name: String {
        switch self {
        case .expense: "支出"
        case .income: "収入"
        case .transfer: "振替"
        }
    }
}
