import Core
import DesignSystem
import Store

public struct EntryRowItem: Identifiable, Equatable {
    public let id: Entry.ID
    public let icon: Icon?
    public let title: String
    public let tag: String?
    public let detail: String?
    public let route: EntryRow.Route?
    public let memo: String?
    public let amount: Int
    public let type: Entry.Kind
    public let isRecurring: Bool
    public let items: [EntryItem]
    public let taxIncluded: Bool
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
        let route = Self.route(for: entry, in: list)
        let wallet = route == nil ? Self.walletText(for: entry, in: list) : nil

        self.init(
            id: entry.id,
            icon: category.flatMap { list.icons[$0.iconId] },
            title: list.title(of: entry),
            tag: tag?.name,
            detail: [dayLabel, wallet].rowDetail,
            route: route,
            memo: memo,
            amount: entry.amount,
            type: entry.type,
            isRecurring: entry.recurringId != nil,
            items: list.items[entry.id, default: []],
            taxIncluded: entry.taxIncluded
        )
    }
}

private extension EntryRowItem {
    static func walletText(
        for entry: Entry,
        in list: EntryList
    ) -> String? {
        let bill = billText(for: entry, in: list) ?? ""
        return list.wallets[entry.walletId].map { $0.name + bill }
    }

    static func billText(
        for entry: Entry,
        in list: EntryList
    ) -> String? {
        guard let month = entry.billMonth else {
            return nil
        }

        let dates = list.cardBills
            .filter { $0.toWalletId == entry.walletId && $0.archivedAt == nil }
            .compactMap { $0.billDate(for: entry.date, in: month) }

        guard
            let date = dates.first,
            dates.count == 1
        else {
            return "（\(month.month)月払い）"
        }

        return "（\(Recurring.billText(paidOn: date))）"
    }

    static func route(
        for entry: Entry,
        in list: EntryList
    ) -> EntryRow.Route? {
        if let transfer = transfer(of: entry, in: list) {
            return route(for: transfer, in: list).map { route in
                EntryRow.Route(
                    source: route.source,
                    destination: "\(route.destination) の手数料"
                )
            }
        }

        guard
            entry.type == .transfer,
            let source = list.wallets[entry.walletId],
            let destination = entry.toWalletId.flatMap({ list.wallets[$0] })
        else {
            return nil
        }

        return EntryRow.Route(
            source: source.name,
            destination: destination.name
        )
    }

    static func transfer(
        of fee: Entry,
        in list: EntryList
    ) -> Entry? {
        guard let transferId = fee.transferId else {
            return nil
        }

        return list.days
            .first { $0.date == fee.date }?
            .entries
            .first { $0.id == transferId && $0.type == .transfer }
    }
}
