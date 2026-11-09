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

                ForEach(content.sections.filter { !$0.rows.isEmpty }) { section in
                    sectionView(section)
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
        let sections: [Section]
    }

    struct Section {
        var amount: Int?
        var isOpen = false

        let title: String
        let rows: [EntryRowItem]
    }
}

extension AssetsEntrySheet.Content {
    static func moved(_ row: AssetsModel.UpcomingBill) -> Self {
        let count = row.movedIn.count + row.movedOut.count
        let day = PeriodText.weekdayDate(row.bill.date)

        return Self(
            id: "moved-\(row.id)",
            amount: row.bill.amount,
            title: "回した記録",
            note: "\(row.title) · \(count) 件 · \(day)に引き落とし",
            sections: [
                .init(title: "この引き落としに入れた", rows: row.movedIn),
                .init(title: "後の引き落としに回した", rows: row.movedOut)
            ]
        )
    }

    static func unpaid(
        _ unpaid: AssetsModel.Unpaid,
        of row: AssetsModel.WalletRow
    ) -> Self {
        let billSections = unpaid.bills.map { group in
            AssetsEntrySheet.Section(
                amount: group.total,
                isOpen: group.bill.isOpen,
                title: "\(BillText.paid(on: group.bill.date)) · \(group.rows.count) 件",
                rows: group.rows
            )
        }

        let later = AssetsEntrySheet.Section(title: "その後に引き落とす", rows: unpaid.later)

        return Self(
            id: "unpaid-\(row.id)",
            amount: unpaid.total,
            title: "未払いの記録",
            note: "\(row.wallet.name) · \(unpaid.count) 件",
            sections: billSections + [later]
        )
    }
}

private extension AssetsEntrySheet {
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
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            SectionTitle(section.title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            if let amount = section.amount {
                AmountText(
                    amount,
                    font: .style(.subheadline, weight: .semibold),
                    color: Palette.accentStrong
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
        .padding(.bottom, 4)
        .overlay(alignment: .bottom) {
            if section.isOpen {
                DashedRule()
                    .stroke(Palette.accent.opacity(.medium), style: .dashed)
                    .frame(height: 1)
            }
        }
    }
}

extension AssetsEntrySheet.Section: Identifiable {
    var id: String {
        title
    }
}

private struct DashedRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))

        return path
    }
}
