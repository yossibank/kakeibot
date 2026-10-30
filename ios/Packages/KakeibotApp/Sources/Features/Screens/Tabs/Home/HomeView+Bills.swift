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
                        billRow(bill)
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
    func billRow(_ bill: CardBill) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(bill.date.month)/\(bill.date.day)")
                    .displayFont(.body)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accent)

                Text(daysText(until: bill.date))
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }
            .frame(width: Self.billDateWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.title(of: bill.recurring))
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .sharedTextScale()

                if bill.shortage > 0 {
                    Text("残高が \(AmountText.text(bill.shortage)) 足りません")
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.rose)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: 8)

            Text(AmountText.text(bill.amount))
                .displayFont(.headline)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
    }
}

private extension HomeView {
    static let billDateWidth: CGFloat = 56

    var billTotalText: String? {
        guard !model.upcomingBills.isEmpty else {
            return nil
        }

        return "合計 \(AmountText.text(model.upcomingBillTotal))"
    }

    func daysText(until date: LocalDate) -> String {
        let days = model.today.days(until: date)
        return days == 1 ? "明日" : "あと \(days) 日"
    }
}
