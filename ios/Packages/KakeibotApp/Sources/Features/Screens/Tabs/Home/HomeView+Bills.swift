import Core
import DesignSystem
import SwiftUI

extension HomeView {
    var billCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let page = model.shownBillPage {
                ViewThatFits(in: .horizontal) {
                    CardHeader(Self.billTitle, note: BillText.total(of: page))
                    CardHeader(Self.billTitle, note: AmountText.text(page.total))
                }

                if model.billPages.count > 1 {
                    billPager(page)
                }

                billList(page)
                    .pageSlide(billSlide, page: page.month)
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
    func billPager(_ page: BillPage) -> some View {
        HStack(spacing: 8) {
            BillPageStepper(
                month: page.month,
                canMoveBackward: model.canMoveBillPage(by: -1),
                canMoveForward: model.canMoveBillPage(by: 1)
            ) { count in
                moveBillPage(by: count)
            }

            Spacer(minLength: 8)

            PageDots(count: model.billPages.count, current: model.billPage)
        }
        .padding(.bottom, 4)
    }

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

            if page.isOpen {
                Text(BillText.openNote)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        Palette.accent.opacity(.faint),
                        in: .rect(cornerRadius: corner.radius(12))
                    )
                    .padding(.vertical, 8)
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
