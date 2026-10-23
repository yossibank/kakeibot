import Core

public extension EntryList {
    func title(of entry: Entry) -> String {
        if let category = entry.categoryId.flatMap({ categories[$0] }) {
            return category.name
        }

        switch entry.type {
        case .transfer: return "振替"
        case .expense, .income: return "未分類"
        }
    }
}
