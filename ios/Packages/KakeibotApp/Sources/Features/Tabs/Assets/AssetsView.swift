import Core
import DesignSystem
import SwiftUI

struct AssetsView: View {
    @Bindable var model: AssetsModel

    let onTransfer: () -> Void
    let onOpenWallet: (Wallet.ID) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                totalCard
                walletGrid

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Palette.rose)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
    }
}

private extension AssetsView {
    var header: some View {
        HStack {
            Text("資産")
                .font(.system(size: 15, design: .serif))
                .tracking(3)
                .foregroundStyle(Palette.gold)

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
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Palette.champagne)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer(minLength: 8)

                Text(changeText)
                    .font(.caption)
                    .foregroundStyle(Palette.gold)
            }

            BalanceTrend(totals: model.monthTotals.map(\.total))
                .frame(height: 70)

            HStack(spacing: 0) {
                ForEach(model.monthTotals) { total in
                    Text("\(total.month.month)月")
                        .font(.system(size: 9))
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
        let color = row.balance < 0 ? Palette.rose : Palette.champagne

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                IconImage(row.icon, size: 15)
                    .foregroundStyle(Palette.gold)

                Text(row.wallet.name)
                    .font(.caption)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
            }

            Text(AmountText.text(row.balance))
                .font(.system(size: 18, design: .serif))
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
        month == model.currentMonth ? Palette.gold : Palette.dusk
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
                    Palette.gold,
                    style: StrokeStyle(lineWidth: 1.6, lineJoin: .round)
                )

                ForEach(points.indices, id: \.self) { index in
                    let isLast = index == points.count - 1
                    let size: CGFloat = isLast ? 8 : 4
                    let color = isLast ? Palette.champagne : Palette.gold

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
