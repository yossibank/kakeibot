import Core
import DesignSystem
import SwiftUI

struct AssetsMovedSheet: View {
    @Environment(\.dismiss) private var dismiss

    let row: AssetsModel.UpcomingBill
    let onOpen: (Entry.ID) -> Void

    var body: some View {
        FittedSheet {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    FlipDate(row.bill.date)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("回した記録")
                            .textFont(.headline)
                            .foregroundStyle(Palette.accentStrong)

                        Text("\(row.title) の引き落としに出し入れした記録です")
                            .textFont(.caption)
                            .foregroundStyle(Palette.subtext)
                    }
                }

                if !row.movedIn.isEmpty {
                    section("この引き落としに入れた", rows: row.movedIn)
                }

                if !row.movedOut.isEmpty {
                    section("後の引き落としに回した", rows: row.movedOut)
                }
            }
        }
    }
}

private extension AssetsMovedSheet {
    func section(
        _ title: String,
        rows: [EntryRowItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .textFont(.caption)
                .tracking(2)
                .foregroundStyle(Palette.subtext)

            VStack(spacing: 0) {
                ForEach(rows) { item in
                    Button {
                        onOpen(item.id)
                        dismiss()
                    } label: {
                        EntryRow(
                            icon: item.icon,
                            title: item.title,
                            tag: item.tag,
                            detail: item.detail,
                            memo: item.memo,
                            amount: item.amount,
                            type: item.type,
                            isRecurring: item.isRecurring
                        )
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) {
                        if item.id != rows.first?.id {
                            Hairline()
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .card()
        }
    }
}
