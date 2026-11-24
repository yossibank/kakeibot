import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension HomeView {
    var billCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(Self.billTitle, note: BillText.note(of: model.output.billPages))

            if model.output.billPages.isEmpty {
                Text("これからの引き落としはありません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.vertical, 16)
            } else {
                if model.output.billPages.count > 1 {
                    BillTabs(
                        pages: model.output.billPages,
                        current: model.output.billPage
                    ) { index in
                        model.state.billPage = index
                    }
                    .padding(.bottom, 4)
                }

                BillPager(
                    current: Binding {
                        model.output.billPage
                    } set: { page in
                        model.state.billPage = page
                    },
                    pages: model.output.billPages,
                    inset: Self.billInset
                ) { page in
                    billList(page)
                }
            }
        }
        .padding(.horizontal, Self.billInset)
        .padding(.bottom, 8)
        .card()
        .haptic(.selection, trigger: model.output.billPage)
        .sharesTextScale(id: model.output.billPages.flatMap(\.bills)
            .map { model.output.title(of: $0.recurring) })
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
                        title: model.output.title(of: bill.recurring),
                        source: model.output.walletName(of: bill.recurring),
                        today: model.state.today,
                        style: .compact
                    )
                }
                .buttonStyle(.plain)
                .topHairline()
            }
        }
    }
}
