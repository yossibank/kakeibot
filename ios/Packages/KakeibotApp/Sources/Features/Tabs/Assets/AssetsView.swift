import Core
import DesignSystem
import SwiftUI

public struct AssetsView: View {
    @Bindable private var model: AssetsModel

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
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle("これからの引き落とし")

                Spacer()

                Text("合計 \(AmountText.text(model.upcomingBillTotal))")
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }

            ForEach(model.upcomingBills) { bill in
                Button {
                    onOpenRecurring(bill.recurring.id)
                } label: {
                    billRow(bill)
                }
                .buttonStyle(.plain)
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

    func billRow(_ bill: AssetsModel.UpcomingBill) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text("\(bill.date.month)/\(bill.date.day)")
                    .textFont(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Palette.text)

                Text(bill.date.weekday.shortName)
                    .textFont(.caption2)
                    .foregroundStyle(bill.date.tint ?? Palette.subtext)
            }
            .frame(width: 44)

            IconBadge(bill.icon, size: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(bill.title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                if let route = bill.route {
                    Text(route)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                AmountText(bill.amount, type: .transfer)
                    .textFont(.subheadline)

                if let period = bill.period {
                    Text("\(RecurringText.period(period)) の利用分")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.hint)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
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
