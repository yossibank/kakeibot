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
                HStack(alignment: .top, spacing: 16) {
                    FlipDate(content.date)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(content.title)
                            .textFont(.headline)
                            .foregroundStyle(Palette.accentStrong)

                        Text(content.note)
                            .textFont(.caption)
                            .foregroundStyle(Palette.subtext)
                    }
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
        let date: LocalDate
        let title: String
        let note: String
        let sections: [Section]
    }

    struct Section {
        let title: String
        let rows: [EntryRowItem]
    }
}

extension AssetsEntrySheet.Content {
    static func moved(_ row: AssetsModel.UpcomingBill) -> Self {
        Self(
            id: "moved-\(row.id)",
            date: row.bill.date,
            title: "回した記録",
            note: "\(row.title) の引き落としに出し入れした記録です",
            sections: [
                .init(title: "この引き落としに入れた", rows: row.movedIn),
                .init(title: "後の引き落としに回した", rows: row.movedOut)
            ]
        )
    }

    static func unpaid(
        _ unpaid: AssetsModel.Unpaid,
        of row: AssetsModel.WalletRow,
        bill: CardBill
    ) -> Self {
        let date = "\(bill.date.month)/\(bill.date.day)"

        return Self(
            id: "unpaid-\(row.id)",
            date: bill.date,
            title: "未払いの記録",
            note: "\(row.wallet.name) で払い、まだ引き落とされていない記録です",
            sections: [
                .init(title: "\(date) に引き落とす", rows: unpaid.billed),
                .init(title: "その後に引き落とす", rows: unpaid.later)
            ]
        )
    }
}

private extension AssetsEntrySheet {
    func sectionView(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(section.title)

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
}

extension AssetsEntrySheet.Section: Identifiable {
    var id: String {
        title
    }
}
