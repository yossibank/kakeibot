import Core
import DesignSystem
import Store

public struct EntryRowItem: Identifiable, Equatable {
    public let id: Entry.ID
    public let icon: Icon?
    public let title: String
    public let tag: String?
    public let detail: String?
    public let memo: String?
    public let amount: Int
    public let type: Entry.Kind
    public let isRecurring: Bool
}

extension EntryRowItem {
    init(
        _ entry: Entry,
        in list: EntryList,
        dayLabel: String? = nil
    ) {
        let category = entry.categoryId.flatMap { list.categories[$0] }
        let tag = entry.tagId.flatMap { list.tags[$0] }
        let memo = entry.memo.flatMap { $0.isEmpty ? nil : $0 }
        let wallets = Self.walletText(for: entry, in: list)

        self.init(
            id: entry.id,
            icon: category.flatMap { list.icons[$0.iconId] },
            title: category?.name ?? Self.title(for: entry.type),
            tag: tag?.name,
            detail: [dayLabel, wallets].rowDetail,
            memo: memo,
            amount: entry.amount,
            type: entry.type,
            isRecurring: entry.recurringId != nil
        )
    }
}

private extension EntryRowItem {
    static func walletText(
        for entry: Entry,
        in list: EntryList
    ) -> String? {
        let source = list.wallets[entry.walletId]?.name

        guard
            entry.type == .transfer,
            let destination = entry.toWalletId.flatMap({ list.wallets[$0] })
        else {
            let bill = entry.billMonth.map { "（\($0.month)月払い）" } ?? ""
            return source.map { $0 + bill }
        }

        return [source, destination.name]
            .compactMap(\.self)
            .joined(separator: " → ")
    }

    static func title(for type: Entry.Kind) -> String {
        switch type {
        case .transfer: "振替"
        case .expense, .income: "未分類"
        }
    }
}
