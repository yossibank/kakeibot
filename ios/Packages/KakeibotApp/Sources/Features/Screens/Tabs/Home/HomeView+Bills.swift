import Core
import DesignSystem
import SwiftUI

extension HomeView {
    var billCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let page = model.shownBillPage {
                CardHeader(Self.billTitle)

                BillTabs(pages: model.billPages, current: model.billPage) { index in
                    moveBillPage(by: index - model.billPage)
                }
                .padding(.bottom, 4)

                billList(page)
                    .pageSlide(billSlide, page: page.month)

                if page.isOpen {
                    BillProgressNote()
                        .padding(.vertical, 8)
                }
            } else {
                CardHeader(Self.billTitle)

                Text("これからの引き落としはありません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.vertical, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .card()
        .onPageSwipe(following: $billSlide, canMove: canMoveBillPage) { direction in
            moveBillPage(by: Self.billCount(of: direction))
        }
        .haptic(.selection, trigger: model.billPage)
        .sharesTextScale(id: model.billPages.flatMap(\.bills).map { model.title(of: $0.recurring) })
    }
}

private extension HomeView {
    func billList(_ page: BillPage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(page.bills, id: \.recurring.id) { bill in
                Button {
                    onOpenRecurring(bill.recurring.id)
                } label: {
                    BillRow(
                        bill,
                        title: model.title(of: bill.recurring),
                        source: model.walletName(of: bill.recurring),
                        today: model.today,
                        style: .compact
                    )
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    Hairline(thickness: 1)
                }
            }
        }
    }
}

private extension HomeView {
    static let billTitle = "これからの引き落とし"

    static func billCount(of direction: PageSwipeDirection) -> Int {
        switch direction {
        case .forward: 1
        case .backward: -1
        }
    }

    func canMoveBillPage(_ direction: PageSwipeDirection) -> Bool {
        model.canMoveBillPage(by: Self.billCount(of: direction))
    }

    func moveBillPage(by count: Int) {
        guard model.canMoveBillPage(by: count) else {
            return
        }

        PageSlide.run($billSlide, forward: count > 0) {
            model.moveBillPage(by: count)
        }
    }
}
