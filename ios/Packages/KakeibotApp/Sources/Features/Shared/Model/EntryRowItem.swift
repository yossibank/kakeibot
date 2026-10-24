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
            title: list.title(of: entry),
            tag: tag?.name,
            detail: [dayLabel, wallets].rowDetail,
            memo: memo,
            amount: entry.amount,
            type: entry.type,
            isRecurring: entry.recurringId != nil
        )
    }
}

extension EntryRowItem {
    static func walletText(
        type: Entry.Kind,
        source: String?,
        destination: String?,
        billMonth: YearMonth?
    ) -> String? {
        guard type == .transfer, let destination else {
            let bill = billMonth.map { "（\($0.month)月払い）" } ?? ""

            return source.map { $0 + bill }
        }

        return [source, destination]
            .compactMap(\.self)
            .joined(separator: " → ")
    }
}

private extension EntryRowItem {
    static func walletText(
        for entry: Entry,
        in list: EntryList
    ) -> String? {
        walletText(
            type: entry.type,
            source: list.wallets[entry.walletId]?.name,
            destination: entry.toWalletId.flatMap { list.wallets[$0]?.name },
            billMonth: entry.billMonth
        )
    }
}
