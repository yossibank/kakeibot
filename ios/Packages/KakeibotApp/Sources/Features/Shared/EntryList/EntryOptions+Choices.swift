import Core
import Store

extension EntryOptions {
    func categories(of type: Entry.Kind) -> [EntryCategory] {
        switch type {
        case .expense: expenseCategories
        case .income: incomeCategories
        case .transfer: []
        }
    }

    func icon(for category: EntryCategory) -> Icon? {
        icons[category.iconId]
    }

    func icon(for wallet: Wallet) -> Icon? {
        icons[wallet.iconId]
    }

    func tags(
        of categoryId: EntryCategory.ID?,
        keeping tagId: EntryTag.ID?
    ) -> [EntryTag] {
        tags.filter { tag in
            tag.categoryId == categoryId
                && (tag.archivedAt == nil || tag.id == tagId)
        }
    }
}

extension Entry.Kind {
    var walletTitle: String {
        switch self {
        case .expense: "支払い元"
        case .income: "入金先"
        case .transfer: "振替元"
        }
    }
}
