public extension Entry.Kind {
    var categoryKind: EntryCategory.Kind? {
        EntryCategory.Kind(rawValue: rawValue)
    }

    var name: String {
        switch self {
        case .expense: "支出"
        case .income: "収入"
        case .transfer: "振替"
        }
    }
}
