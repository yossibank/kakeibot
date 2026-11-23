import Core
import DesignSystem
import SwiftUI

struct AssetsEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let content: Content
    let onOpen: (Entry.ID) -> Void

    var body: some View {
        FittedSheet {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .textFont(.subheadline, weight: .semibold)
                        .foregroundStyle(Palette.subtext)

                    AmountText(
                        content.amount,
                        font: .size(.largeTitle, weight: .bold),
                        color: Palette.accentStrong
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                    Text(content.note)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                }

                ForEach(content.groups) { group in
                    groupView(group)
                }
            }
        }
    }
}

extension AssetsEntrySheet {
    struct Content: Identifiable {
        let id: String
        let amount: Int
        let title: String
        let note: String
        let groups: [Group]
    }

    struct Group: Identifiable {
        var title: String?
        var amount: Int?

        let id: String
        let sections: [Section]
    }

    struct Section: Identifiable {
        var amount: Int?
        var bill: CardBill?

        let id: String
        let title: String
        let rows: [EntryRowItem]
    }
}

extension AssetsEntrySheet.Content {
    static func moved(_ row: AssetsModel.UpcomingBill) -> Self {
        let count = row.movedIn.count + row.movedOut.count
        let day = PeriodText.weekdayDate(row.bill.date)

        let sections: [AssetsEntrySheet.Section] = [
            .init(id: "moved-in", title: "この引き落としに入れた", rows: row.movedIn),
            .init(id: "moved-out", title: "後の引き落としに回した", rows: row.movedOut)
        ]

        return Self(
            id: "moved-\(row.id)",
            amount: row.bill.amount,
            title: "回した記録",
            note: "\(row.title) · \(count) 件 · \(day)に引き落とし",
            groups: [.init(id: "moved", sections: sections)]
        )
    }

    static func unpaid(of rows: [AssetsModel.WalletRow]) -> Self {
        let cards = rows.compactMap { row in
            row.unpaid.map { (row, $0) }
        }

        let groups = cards.map { row, unpaid in
            AssetsEntrySheet.Group(
                title: row.wallet.name,
                amount: unpaid.total,
                id: "unpaid-\(row.id)",
                sections: sections(of: unpaid, in: row)
            )
        }

        let count = cards.reduce(0) { $0 + $1.1.count }
        let total = cards.reduce(0) { $0 + $1.1.total }
        let name = cards.count == 1 ? cards.first?.0.wallet.name : nil

        return Self(
            id: "unpaid",
            amount: total,
            title: "未払いの記録",
            note: "\(name ?? "カード \(cards.count) 枚") · \(count) 件",
            groups: groups
        )
    }
}

private extension AssetsEntrySheet.Content {
    static func sections(
        of unpaid: AssetsModel.Unpaid,
        in row: AssetsModel.WalletRow
    ) -> [AssetsEntrySheet.Section] {
        let bills = unpaid.bills.map { group in
            AssetsEntrySheet.Section(
                amount: group.total,
                bill: group.bill,
                id: "bill-\(group.bill.recurring.id)-\(group.bill.date)",
                title: "\(Recurring.billText(paidOn: group.bill.date)) · \(group.rows.count) 件",
                rows: group.rows
            )
        }

        let later = AssetsEntrySheet.Section(
            id: "later-\(row.id)",
            title: "その後に引き落とす",
            rows: unpaid.later
        )

        return bills + [later]
    }
}

private extension AssetsEntrySheet {
    func groupView(_ group: Group) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = group.title {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .textFont(.headline)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if let amount = group.amount {
                        AmountText(
                            amount,
                            font: .style(.headline, weight: .semibold),
                            color: Palette.accentStrong
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
                }
            }

            ForEach(group.sections.filter { !$0.rows.isEmpty }) { section in
                sectionView(section)
            }
        }
    }

    func sectionView(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(section)

            VStack(spacing: 0) {
                ForEach(section.rows) { item in
                    Button {
                        onOpen(item.id)
                        dismiss()
                    } label: {
                        EntryRow(
                            icon: item.icon,
                            title: item.title,
                            tag: item.tag,
                            detail: item.detail,
                            route: item.route,
                            memo: item.memo,
                            amount: item.amount,
                            type: item.type,
                            isRecurring: item.isRecurring
                        )
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) {
                        if item.id != section.rows.first?.id {
                            Hairline()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .card()
            .sharesTextScale(id: section.rows)
        }
    }

    func sectionHeader(_ section: Section) -> some View {
        HStack(spacing: 8) {
            if let bill = section.bill {
                BillMark(isOpen: bill.isOpen)
            }

            SectionTitle(section.title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if section.bill?.isOpen == true {
                Text(BillText.estimate)
                    .textFont(.caption2, weight: .semibold)
                    .foregroundStyle(Palette.hint)
                    .fixedSize()
            }

            Spacer(minLength: 8)

            if let amount = section.amount {
                AmountText(
                    amount,
                    font: .style(.subheadline, weight: .semibold),
                    color: section.bill?.isOpen == true ? Palette.subtext : Palette.accentStrong
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
        .padding(.bottom, 4)
    }
}
