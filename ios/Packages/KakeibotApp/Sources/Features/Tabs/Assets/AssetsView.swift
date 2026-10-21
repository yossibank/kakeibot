import Core
import DesignSystem
import SwiftUI

public struct AssetsView: View {
    @Bindable private var model: AssetsModel

    @Environment(\.themeStyle.corner) private var corner

    private let onTransfer: () -> Void
    private let onOpenWallet: (Wallet.ID) -> Void
    private let onOpenRecurring: (Recurring.ID) -> Void

    public init(
        model: AssetsModel,
        onTransfer: @escaping () -> Void,
        onOpenWallet: @escaping (Wallet.ID) -> Void,
        onOpenRecurring: @escaping (Recurring.ID) -> Void
    ) {
        self.model = model
        self.onTransfer = onTransfer
        self.onOpenWallet = onOpenWallet
        self.onOpenRecurring = onOpenRecurring
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                totalCard

                if !model.upcomingBills.isEmpty {
                    billCard
                }

                walletGrid
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
    }
}

private extension AssetsView {
    var header: some View {
        HStack {
            Text("資産")
                .displayFont(.body)
                .tracking(3)
                .foregroundStyle(Palette.accent)

            Spacer()

            HeaderButton(
                systemImage: "arrow.left.arrow.right",
                title: "振替",
                action: onTransfer
            )
        }
    }

    var totalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("残高の合計")

            HStack(alignment: .firstTextBaseline) {
                Text(AmountText.text(model.total))
                    .displayFont(.largeTitle, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer(minLength: 8)

                Text(changeText)
                    .textFont(.caption)
                    .foregroundStyle(Palette.accent)
            }

            BalanceTrend(totals: model.monthTotals.map(\.total))
                .frame(height: 70)

            HStack(spacing: 0) {
                ForEach(model.monthTotals) { total in
                    Text("\(total.month.month)月")
                        .textFont(size: .micro)
                        .foregroundStyle(monthColor(total.month))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .card(cornerRadius: 24)
    }

    var billCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("これからの引き落とし")

                Spacer()

                Text("合計 \(AmountText.text(model.upcomingBillTotal))")
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }

            VStack(spacing: 10) {
                ForEach(model.upcomingBills) { row in
                    Button {
                        onOpenRecurring(row.id)
                    } label: {
                        billRow(row)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .card(cornerRadius: 24)
    }

    var walletGrid: some View {
        LazyVGrid(columns: Self.columns, spacing: 8) {
            ForEach(model.rows) { row in
                Button {
                    onOpenWallet(row.wallet.id)
                } label: {
                    walletTile(row)
                }
                .buttonStyle(.plain)
            }
        }
    }

    func billRow(_ row: AssetsModel.UpcomingBill) -> some View {
        HStack(alignment: .top, spacing: 14) {
            dateChip(row.bill.date)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title)
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)

                        if let period = row.bill.period {
                            Text("\(RecurringText.period(period)) の利用分")
                                .textFont(.caption2)
                                .foregroundStyle(Palette.subtext)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    Text(AmountText.text(row.bill.amount))
                        .displayFont(.headline)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                }

                balanceBar(row.bill)

                HStack(alignment: .firstTextBaseline) {
                    Text(balanceText(row))
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(balanceColor(row.bill))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 8)

                    Text(daysText(until: row.bill.date))
                        .textFont(.caption2)
                        .foregroundStyle(Palette.accent)
                }
            }
        }
        .padding(12)
        .background(
            Palette.accent.opacity(.faint),
            in: .rect(cornerRadius: corner.radius(18))
        )
        .contentShape(.rect)
    }

    func dateChip(_ date: LocalDate) -> some View {
        VStack(spacing: 0) {
            Text("\(date.month)月")
                .textFont(.caption2)
                .foregroundStyle(Palette.backgroundBottom)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .background(Palette.accent)

            Text("\(date.day)")
                .displayFont(.title)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
                .padding(.top, 2)

            Text(date.weekday.shortName)
                .textFont(.caption2)
                .foregroundStyle(date.tint ?? Palette.subtext)
                .padding(.bottom, 4)
        }
        .frame(width: 52)
        .background(Palette.panel)
        .clipShape(.rect(cornerRadius: corner.radius(12)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(12))
                .stroke(Palette.outline, lineWidth: 1)
        }
    }

    func balanceBar(_ bill: CardBill) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.accent.opacity(.soft))

                Capsule()
                    .fill(balanceColor(bill))
                    .frame(width: proxy.size.width * Self.share(of: bill))
            }
        }
        .frame(height: 4)
    }

    func walletTile(_ row: AssetsModel.WalletRow) -> some View {
        let color = row.balance < 0 ? Palette.rose : Palette.accentStrong

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                IconImage(row.icon, size: 15)
                    .foregroundStyle(Palette.accent)

                Text(row.wallet.name)
                    .textFont(.caption)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
            }

            Text(AmountText.text(row.balance))
                .displayFont(.headline)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let next = row.nextBill {
                Text("次の引き落とし \(AmountText.text(next))")
                    .textFont(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .card(cornerRadius: 18)
        .contentShape(.rect)
    }
}

private extension AssetsView {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 2
    )

    var changeText: String {
        let change = model.changeFromLastMonth
        let sign = change > 0 ? "+" : ""
        return "先月末より \(sign)\(AmountText.text(change))"
    }

    static func share(of bill: CardBill) -> CGFloat {
        guard bill.balanceBefore > 0 else {
            return 1
        }

        let share = Double(bill.amount) / Double(bill.balanceBefore)
        return CGFloat(min(share, 1))
    }

    func balanceText(_ row: AssetsModel.UpcomingBill) -> String {
        let source = row.source ?? "口座"
        let bill = row.bill

        guard bill.shortage == 0 else {
            return "\(source)が \(AmountText.text(bill.shortage)) 足りません"
        }

        let before = AmountText.text(bill.balanceBefore)
        let after = AmountText.text(bill.balanceAfter)
        return "\(source) \(before) → \(after)"
    }

    func balanceColor(_ bill: CardBill) -> Color {
        bill.shortage > 0 ? Palette.rose : Palette.accent
    }

    func daysText(until date: LocalDate) -> String {
        let days = model.today.days(until: date)
        return days == 1 ? "明日" : "あと \(days) 日"
    }

    func monthColor(_ month: YearMonth) -> Color {
        month == model.currentMonth ? Palette.accent : Palette.hint
    }
}

private struct BalanceTrend: View {
    let totals: [Int]

    var body: some View {
        GeometryReader { proxy in
            let points = points(in: proxy.size)

            ZStack {
                Path { path in
                    path.addLines(points)
                }
                .stroke(
                    Palette.accent,
                    style: StrokeStyle(lineWidth: 1.6, lineJoin: .round)
                )

                ForEach(points.indices, id: \.self) { index in
                    let isLast = index == points.count - 1
                    let size: CGFloat = isLast ? 8 : 4
                    let color = isLast ? Palette.accentStrong : Palette.accent

                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .position(points[index])
                }
            }
        }
    }

    func points(in size: CGSize) -> [CGPoint] {
        let low = totals.min() ?? 0
        let high = totals.max() ?? 0
        let range = CGFloat(max(high - low, 1))
        let step = size.width / CGFloat(max(totals.count, 1))
        let inset: CGFloat = 6

        return totals.enumerated().map { index, total in
            let ratio = high == low ? 0.5 : CGFloat(total - low) / range
            let x = step * (CGFloat(index) + 0.5)
            let y = inset + (size.height - inset * 2) * (1 - ratio)
            return CGPoint(x: x, y: y)
        }
    }
}
