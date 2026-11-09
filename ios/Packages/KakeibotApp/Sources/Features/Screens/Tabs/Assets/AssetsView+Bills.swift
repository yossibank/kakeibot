import Core
import DesignSystem
import SwiftUI

extension AssetsView {
    var billCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(Self.billTitle)

            if !model.billPages.isEmpty {
                BillTabs(pages: model.billPages, current: model.billPage) { index in
                    moveBillPage(by: index - model.billPage)
                }
                .padding(.bottom, 12)
            }

            VStack(spacing: 12) {
                ForEach(model.shownUpcomingBills) { row in
                    Button {
                        onOpenRecurring(row.id)
                    } label: {
                        billRow(row)
                    }
                    .buttonStyle(.plain)
                }
            }
            .pageSlide(billSlide, page: model.shownBillPage?.month)
            .sharesTextScale(id: model.upcomingBills.map(\.source))

            if model.shownBillPage?.isOpen == true {
                BillProgressNote()
                    .padding(.top, 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .card()
        .onPageSwipe(following: $billSlide, canMove: canMoveBillPage) { direction in
            moveBillPage(by: Self.billCount(of: direction))
        }
        .haptic(.selection, trigger: model.billPage)
    }
}

private extension AssetsView {
    static let billTitle = "これからの引き落とし"

    static func movesText(of row: AssetsModel.UpcomingBill) -> String? {
        let movedIn = row.movedIn.count
        let movedOut = row.movedOut.count
        let inText = movedIn > 0 ? ["前から \(movedIn) 件"] : []
        let outText = movedOut > 0 ? ["後へ \(movedOut) 件"] : []
        let parts = inText + outText
        return parts.isEmpty ? nil : parts.joined(separator: "・")
    }

    static func billCount(of direction: PageSwipeDirection) -> Int {
        switch direction {
        case .forward: 1
        case .backward: -1
        }
    }

    func canMoveBillPage(_ direction: PageSwipeDirection) -> Bool {
        model.canMoveBillPage(by: Self.billCount(of: direction))
    }
}

private extension AssetsView {
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

private extension AssetsView {
    func moveBillPage(by count: Int) {
        guard model.canMoveBillPage(by: count) else {
            return
        }

        PageSlide.run($billSlide, forward: count > 0) {
            model.moveBillPage(by: count)
        }
    }
}
