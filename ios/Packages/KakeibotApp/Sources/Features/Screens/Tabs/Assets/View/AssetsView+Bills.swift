import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension AssetsView {
    var billCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(Self.billTitle, note: BillText.note(of: model.output.billPages))

            if !model.output.billPages.isEmpty {
                if model.output.billPages.count > 1 {
                    BillTabs(
                        pages: model.output.billPages,
                        current: model.state.billPage
                    ) { index in
                        model.state.billPage = index
                    }
                    .padding(.bottom, 12)
                }

                ResizingPager(
                    current: Bindable(model.state).billPage,
                    pages: model.output.billPages,
                    id: \.month,
                    inset: Self.billInset
                ) { page in
                    billList(page)
                }
                .sharesTextScale(id: model.output.upcomingBills.map(\.source))
            }
        }
        .padding(.horizontal, Self.billInset)
        .padding(.bottom, 16)
        .card()
        .haptic(.selection, trigger: model.state.billPage)
    }
}

private extension AssetsView {
    func billList(_ page: BillPage) -> some View {
        VStack(spacing: 12) {
            ForEach(model.output.upcomingBills(in: page.month)) { row in
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
            today: model.output.today,
            style: .detailed
        ) {
            if let moves = Self.movesText(of: row) {
                Button {
                    model.state.present(.entries(.moved(row)))
                } label: {
                    HStack(spacing: 4) {
                        Label(
                            moves,
                            systemImage: "arrow.uturn.right"
                        )
                        .lineLimit(2)

                        DisclosureMark(.strongLink)
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
