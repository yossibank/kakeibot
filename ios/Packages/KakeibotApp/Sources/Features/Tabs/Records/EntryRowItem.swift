import Core
import Store

public struct EntryRowItem: Identifiable, Equatable {
    public let id: Entry.ID
    public let icon: Icon?
    public let title: String
    public let detail: String?
    public let amount: Int
    public let type: Entry.Kind
}

extension EntryRowItem {
    init(
        _ entry: Entry,
        in list: EntryList,
        dayLabel: String? = nil
    ) {
        let category = entry.categoryId.flatMap { list.categories[$0] }
        let wallet = list.wallets[entry.walletId]
        let memo = entry.memo.flatMap { $0.isEmpty ? nil : $0 }
        let parts = [dayLabel, memo, wallet?.name].compactMap(\.self)

        self.init(
            id: entry.id,
            icon: category.flatMap { list.icons[$0.iconId] },
            title: category?.name ?? Self.title(for: entry.type),
            detail: parts.isEmpty ? nil : parts.joined(separator: "・"),
            amount: entry.amount,
            type: entry.type
        )
    }
}

private extension EntryRowItem {
    static func title(for type: Entry.Kind) -> String {
        switch type {
        case .transfer: "振替"
        case .expense, .income: "未分類"
        }
    }
}
