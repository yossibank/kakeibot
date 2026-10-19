import Core
import DesignSystem
import SwiftUI

public struct AssetsView: View {
    @Bindable private var model: AssetsModel

    private let onTransfer: () -> Void
    private let onOpenWallet: (Wallet.ID) -> Void

    public init(
        model: AssetsModel,
        onTransfer: @escaping () -> Void,
        onOpenWallet: @escaping (Wallet.ID) -> Void
    ) {
        self.model = model
        self.onTransfer = onTransfer
        self.onOpenWallet = onOpenWallet
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                totalCard
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
                .font(.serif(.body))
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
                    .font(.serif(.largeTitle, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentLight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer(minLength: 8)

                Text(changeText)
                    .font(.caption)
                    .foregroundStyle(Palette.accent)
            }

            BalanceTrend(totals: model.monthTotals.map(\.total))
                .frame(height: 70)

            HStack(spacing: 0) {
                ForEach(model.monthTotals) { total in
                    Text("\(total.month.month)月")
                        .font(.sans(.micro))
                        .foregroundStyle(monthColor(total.month))
                        .frame(maxWidth: .infinity)
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

    func walletTile(_ row: AssetsModel.WalletRow) -> some View {
        let color = row.balance < 0 ? Palette.rose : Palette.accentLight

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                IconImage(row.icon, size: 15)
                    .foregroundStyle(Palette.accent)

                Text(row.wallet.name)
                    .font(.caption)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
            }

            Text(AmountText.text(row.balance))
                .font(.serif(.headline))
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
                    let color = isLast ? Palette.accentLight : Palette.accent

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
