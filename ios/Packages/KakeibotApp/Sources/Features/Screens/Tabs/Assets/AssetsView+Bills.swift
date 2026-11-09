import Core
import DesignSystem
import SwiftUI

extension AssetsView {
    var billCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(Self.billTitle, note: BillText.note(of: model.billPages))

            if !model.billPages.isEmpty {
                if model.billPages.count > 1 {
                    BillTabs(pages: model.billPages, current: model.billPage) { index in
                        model.billPage = index
                    }
                    .padding(.bottom, 12)
                }

                BillPager(
                    current: $model.billPage,
                    pages: model.billPages,
                    inset: Self.billInset
                ) { page in
                    billList(page)
                }
                .sharesTextScale(id: model.upcomingBills.map(\.source))
            }
        }
        .padding(.horizontal, Self.billInset)
        .padding(.bottom, 16)
        .card()
        .haptic(.selection, trigger: model.billPage)
    }
}

private extension AssetsView {
    static let billTitle = "これからの引き落とし"
    static let billInset: CGFloat = 16

    static func movesText(of row: AssetsModel.UpcomingBill) -> String? {
        let movedIn = row.movedIn.count
        let movedOut = row.movedOut.count
        let inText = movedIn > 0 ? ["前から \(movedIn) 件"] : []
        let outText = movedOut > 0 ? ["後へ \(movedOut) 件"] : []
        let parts = inText + outText
        return parts.isEmpty ? nil : parts.joined(separator: "・")
    }
}

private extension AssetsView {
    func billList(_ page: BillPage) -> some View {
        VStack(spacing: 12) {
            ForEach(model.upcomingBills(in: page.month)) { row in
                Button {
                    onOpenRecurring(row.id)
                } label: {
                    billRow(row)
                }
                .buttonStyle(.plain)
            }
        }
    }

    func billRow(_ row: AssetsModel.UpcomingBill) -> some View {
        BillRow(
            row.bill,
            title: row.title,
            source: row.source,
            today: model.today,
            style: .detailed
        ) {
            if let moves = Self.movesText(of: row) {
                Button {
                    entrySheet = .moved(row)
                } label: {
                    HStack(spacing: 4) {
                        Label(
                            moves,
                            systemImage: "arrow.uturn.right"
                        )
                        .lineLimit(2)

                        Image(systemName: "chevron.right")
                            .sansFont(.micro, weight: .bold)
                    }
                    .textFont(.caption2)
                    .foregroundStyle(Palette.accent)
                    .padding(.vertical, 4)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
