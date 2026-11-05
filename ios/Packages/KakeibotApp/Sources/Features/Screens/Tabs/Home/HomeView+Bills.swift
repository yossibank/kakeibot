import Core
import DesignSystem
import SwiftUI

extension HomeView {
    var billCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("これからの引き落とし", note: billTotalText)

            if model.upcomingBills.isEmpty {
                Text("これからの引き落としはありません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.vertical, 16)
            } else {
                ForEach(model.upcomingBills, id: \.recurring.id) { bill in
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
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .card()
        .sharesTextScale(id: model.upcomingBills.map { model.title(of: $0.recurring) })
    }
}

private extension HomeView {
    var billTotalText: String? {
        guard !model.upcomingBills.isEmpty else {
            return nil
        }

        return "合計 \(AmountText.text(model.upcomingBillTotal))"
    }
}
