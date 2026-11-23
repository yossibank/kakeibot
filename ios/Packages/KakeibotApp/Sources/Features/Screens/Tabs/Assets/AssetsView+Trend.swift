import Core
import DesignSystem
import SwiftUI

extension AssetsView {
    var trendContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.showsNetWorth {
                netWorthRow
            }

            AssetsBalanceTrend(
                totals: model.monthTotals.map(\.total),
                netWorths: netWorths
            )
            .frame(height: 70)

            if model.showsNetWorth {
                trendLegend
            }

            HStack(spacing: 0) {
                ForEach(model.monthTotals) { total in
                    Text("\(total.month.month)月")
                        .textFont(size: .micro)
                        .foregroundStyle(monthColor(total.month))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private extension AssetsView {
    var trendLegend: some View {
        HStack(spacing: 16) {
            legend("手元のお金", color: Palette.accent)
            legend("純資産", color: AssetsBalanceTrend.netWorthColor)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    var netWorthTitle: some View {
        Text("純資産")
            .textFont(.caption)
            .foregroundStyle(Palette.text)
            .fixedSize()
    }

    var netWorthNote: some View {
        Text("投資と借入を含む")
            .textFont(.caption2)
            .foregroundStyle(Palette.hint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    var netWorthAmount: some View {
        AmountText(
            model.holdings.netWorth,
            font: .size(.headline),
            color: Palette.accentStrong
        )
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }

    var netWorthRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        netWorthTitle

                        netWorthNote
                    }

                    Spacer(minLength: 8)

                    netWorthAmount
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        netWorthTitle

                        netWorthNote
                    }

                    netWorthAmount
                }
            }

            if !owedSections.isEmpty {
                VStack(spacing: 4) {
                    SplitBar(
                        ownedShare,
                        leading: Palette.accent,
                        trailing: Palette.accent.opacity(.muted)
                    )

                    HStack {
                        Text("資産 \(Yen.text(ownedTotal))")

                        Spacer(minLength: 8)

                        Text("負債 \(Yen.text(-owedTotal))")
                    }
                    .textFont(size: .micro)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            Palette.accent.opacity(.faint),
            in: .rect(cornerRadius: corner.radius(16))
        )
    }

    func legend(
        _ title: String,
        color: Color
    ) -> some View {
        HStack(spacing: 8) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 1))
                path.addLine(to: CGPoint(x: 16, y: 1))
            }
            .stroke(color, lineWidth: 1.6)
            .frame(width: 16, height: 2)

            Text(title)
                .textFont(size: .micro)
                .foregroundStyle(Palette.subtext)
        }
    }
}

private extension AssetsView {
    var ownedTotal: Int {
        ownedSections.flatMap(\.rows).reduce(0) { $0 + $1.balance }
    }

    var owedTotal: Int {
        owedSections.flatMap(\.rows).reduce(0) { $0 + $1.balance }
    }

    var ownedShare: Double {
        let owned = max(ownedTotal, 0)
        let owed = max(-owedTotal, 0)
        let total = owned + owed
        return total == 0 ? 1 : Double(owned) / Double(total)
    }

    var netWorths: [Int]? {
        model.showsNetWorth ? model.monthTotals.map(\.netWorth) : nil
    }

    func monthColor(_ month: YearMonth) -> Color {
        month == model.currentMonth ? Palette.accent : Palette.hint
    }
}
