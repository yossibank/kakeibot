import Core
import DesignSystem
import SwiftUI

struct AssetsBillSchedule: View {
    let bills: [CardBill]
    let showsAmounts: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(bills, id: \.self) { bill in
                HStack(spacing: 8) {
                    mark(of: bill)

                    ViewThatFits(in: .horizontal) {
                        line(of: bill, status: Self.status(of: bill))

                        line(of: bill, status: Self.shortStatus(of: bill))

                        VStack(alignment: .leading, spacing: 2) {
                            line(of: bill, status: nil)

                            statusText(Self.shortStatus(of: bill), of: bill)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .lineLimit(1)
                .monospacedDigit()
                .frame(minHeight: 22)
            }
        }
    }
}

private extension AssetsBillSchedule {
    static let widestDate = "00/00払い"

    static func status(of bill: CardBill) -> String {
        bill.isOpen ? BillText.estimate(of: bill) : BillText.settled
    }

    static func shortStatus(of bill: CardBill) -> String {
        bill.isOpen ? BillText.estimate : BillText.settled
    }
}

private extension AssetsBillSchedule {
    func mark(of bill: CardBill) -> some View {
        VStack(spacing: 0) {
            connector(isShown: bill != bills.first)

            BillMark(isOpen: bill.isOpen)

            connector(isShown: bill != bills.last)
        }
        .frame(maxHeight: .infinity)
    }

    func connector(isShown: Bool) -> some View {
        Rectangle()
            .fill(isShown ? Palette.accent.opacity(.soft) : .clear)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }

    func line(
        of bill: CardBill,
        status: String?
    ) -> some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                Text(Self.widestDate)
                    .hidden()

                Text(Recurring.billText(paidOn: bill.date))
            }
            .textFont(.caption)
            .foregroundStyle(Palette.subtext)
            .fixedSize()

            if let status {
                statusText(status, of: bill)
            }

            Spacer(minLength: 8)

            if showsAmounts {
                AmountText(
                    bill.amount,
                    font: .style(.caption, weight: .semibold),
                    color: bill.isOpen ? Palette.subtext : Palette.text
                )
                .fixedSize()
            }
        }
    }

    func statusText(
        _ text: String,
        of bill: CardBill
    ) -> some View {
        Text(text)
            .textFont(.caption2, weight: bill.isOpen ? .regular : .semibold)
            .foregroundStyle(bill.isOpen ? Palette.hint : Palette.accent)
            .fixedSize()
    }
}
