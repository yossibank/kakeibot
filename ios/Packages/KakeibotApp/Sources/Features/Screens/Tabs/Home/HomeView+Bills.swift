import Core
import DesignSystem
import SwiftUI

extension HomeView {
    var billCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(Self.billTitle, note: BillText.note(of: model.billPages))

            if model.billPages.isEmpty {
                Text("これからの引き落としはありません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.vertical, 16)
            } else {
                if model.billPages.count > 1 {
                    BillTabs(pages: model.billPages, current: model.billPage) { index in
                        model.billPage = index
                    }
                    .padding(.bottom, 4)
                }

                BillPager(
                    current: $model.billPage,
                    pages: model.billPages,
                    inset: Self.billInset
                ) { page in
                    billList(page)
                }
            }
        }
        .padding(.horizontal, Self.billInset)
        .padding(.bottom, 8)
        .card()
        .haptic(.selection, trigger: model.billPage)
        .sharesTextScale(id: model.billPages.flatMap(\.bills).map { model.title(of: $0.recurring) })
    }
}

private extension HomeView {
    static let billTitle = "これからの引き落とし"
    static let billInset: CGFloat = 16
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
