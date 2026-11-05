import Core
import DesignSystem
import SwiftUI

struct BillRow<Moves: View>: View {
    @Environment(\.themeStyle.corner) private var corner

    let bill: CardBill
    let title: String
    let source: String?
    let today: LocalDate
    let style: Style
    let moves: Moves

    init(
        _ bill: CardBill,
        title: String,
        source: String?,
        today: LocalDate,
        style: Style,
        @ViewBuilder moves: () -> Moves
    ) {
        self.bill = bill
        self.title = title
        self.source = source
        self.today = today
        self.style = style
        self.moves = moves()
    }

    var body: some View {
        switch style {
        case .compact: compact
        case .detailed: detailed
        }
    }
}

extension BillRow where Moves == EmptyView {
    init(
        _ bill: CardBill,
        title: String,
        source: String?,
        today: LocalDate,
        style: Style
    ) {
        self.init(
            bill,
            title: title,
            source: source,
            today: today,
            style: style
        ) {
            EmptyView()
        }
    }
}

extension BillRow {
    enum Style {
        case compact
        case detailed
    }

    static func share(of bill: CardBill) -> Double {
        guard bill.balanceBefore > 0 else {
            return 1
        }

        let share = Double(bill.amount) / Double(bill.balanceBefore)

        return min(share, 1)
    }
}

private extension BillRow {
    var balanceColor: Color {
        bill.shortage > 0 ? Palette.rose : Palette.accent
    }

    var daysText: String {
        BillText.days(until: bill.date, today: today)
    }
}

private extension BillRow {
    var compact: some View {
        HStack(spacing: 12) {
            FlipDate(bill.date, isCompact: true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    titleText

                    Spacer(minLength: 8)

                    amountText
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(BillText.source(source))
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)

                    Text("·")
                        .foregroundStyle(Palette.subtext)

                    Text(daysText)
                        .foregroundStyle(Palette.accent)
                        .fixedSize()
                }
                .textFont(.caption2)

                if bill.shortage > 0 {
                    shortageText
                }
            }
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
    }

    var detailed: some View {
        HStack(alignment: .top, spacing: 16) {
            FlipDate(bill.date)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.text)
                            .lineLimit(2)

                        if let period = bill.period {
                            ViewThatFits(in: .horizontal) {
                                Text("\(RecurringText.period(period)) の利用分")

                                Text(RecurringText.period(period))

                                Text("\(period.upperBound.month)/\(period.upperBound.day) 締め")
                            }
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                            .lineLimit(1)
                        }

                        moves
                    }

                    Spacer(minLength: 8)

                    amountText
                }

                balanceBar

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(BillText.source(source))
                            .sharedTextScale()

                        Spacer(minLength: 8)

                        Text(daysText)
                            .foregroundStyle(Palette.accent)
                    }

                    Text(BillText.balance(bill))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .textFont(.caption2)
                .foregroundStyle(balanceColor)
            }
        }
        .padding(12)
        .background(
            Palette.accent.opacity(.faint),
            in: .rect(cornerRadius: corner.radius(20))
        )
        .contentShape(.rect)
    }

    var titleText: some View {
        Text(title)
            .textFont(.subheadline)
            .foregroundStyle(Palette.text)
            .sharedTextScale()
    }

    var amountText: some View {
        Text(AmountText.text(bill.amount))
            .displayFont(.headline)
            .monospacedDigit()
            .foregroundStyle(Palette.accentStrong)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    var shortageText: some View {
        Text(BillText.shortage(bill.shortage))
            .textFont(.caption2)
            .monospacedDigit()
            .foregroundStyle(Palette.rose)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    var balanceBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.accent.opacity(.soft))

                Capsule()
                    .fill(balanceColor)
                    .frame(width: proxy.size.width * Self.share(of: bill))
            }
        }
        .frame(height: 4)
    }
}
