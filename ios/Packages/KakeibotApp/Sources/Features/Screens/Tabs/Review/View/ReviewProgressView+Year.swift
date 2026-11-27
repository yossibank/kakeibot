import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension ReviewProgressView {
    func yearCard(_ year: ReviewYearProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ReviewReportTitle(title: "\(currentName)の 12 か月")

            yearSpent(year)

            yearChart(year)

            yearStats(year)
        }
        .reviewHero()
    }
}

private extension ReviewProgressView {
    func yearSpent(_ year: ReviewYearProgress) -> some View {
        let spent = ReviewYen.number(year.spent)

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("今日までに使った")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(spent)
                        .displayFont(.title, weight: .bold)
                        .foregroundStyle(Palette.gold)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text("円")
                        .displayFont(.small, weight: .bold)
                        .foregroundStyle(Palette.accent)
                        .fixedSize()
                }
            }

            if let previous = year.previousSpent {
                let difference = previous - year.spent
                let value = ReviewYen.number(abs(difference))
                let suffix = difference >= 0 ? "少ない" : "多い"
                let color = difference >= 0 ? Palette.accent : Palette.increase

                Rectangle()
                    .fill(Palette.line)
                    .frame(height: 1)

                ReviewReportLead(
                    caption: "前の年の同じ日までより",
                    value: value,
                    suffix: suffix,
                    color: color
                )
            }
        }
    }

    func yearStats(_ year: ReviewYearProgress) -> some View {
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            GridRow {
                ReviewReportStatTile(
                    title: "月の平均",
                    systemImage: "chart.bar",
                    value: year.average.map(ReviewYen.number) ?? "−",
                    unit: "円",
                    note: "締めた \(year.closedMonths.count) か月"
                )

                ReviewReportStatTile(
                    title: "いちばん多い月",
                    systemImage: "flame",
                    value: year.peak.map { ReviewYen.number($0.total) } ?? "−",
                    unit: "円",
                    note: year.peak?.name
                )
            }

            if year.budgetedCount > 0 {
                let ratio = Double(year.withinBudgetCount) / Double(year.budgetedCount)

                GridRow {
                    ReviewReportStatTile(
                        title: "予算内の月",
                        systemImage: "rosette",
                        value: "\(year.withinBudgetCount)",
                        unit: "/ \(year.budgetedCount) か月",
                        progress: ratio
                    )
                    .gridCellColumns(2)
                }
            }
        }
        .reviewStatGrid()
    }

    func yearChart(_ year: ReviewYearProgress) -> some View {
        let largest = max(year.largest, 1)
        let averageRatio = year.average.map { Double($0) / Double(largest) }

        return VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(year.months) { month in
                    Button {
                        onOpenMonth(month)
                    } label: {
                        yearBar(month, ratio: Double(month.total) / Double(largest))
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(month.state == .upcoming)
                }
            }
            .frame(height: Self.chartHeight)
            .overlay(alignment: .bottom) {
                if let averageRatio {
                    Rectangle()
                        .stroke(Palette.accent.opacity(.strong), style: .dashed)
                        .frame(height: 0.5)
                        .offset(y: -Self.chartHeight * averageRatio)
                }
            }

            HStack(spacing: 4) {
                ForEach(year.months) { month in
                    Text(month.name)
                        .textFont(.caption2)
                        .foregroundStyle(Self.labelColor(of: month))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                }
            }

            if averageRatio != nil {
                HStack(spacing: 4) {
                    Rectangle()
                        .stroke(Palette.accent.opacity(.strong), style: .dashed)
                        .frame(width: 16, height: 0.5)

                    Text("月の平均")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    func yearBar(
        _ month: ReviewYearProgress.Month,
        ratio: Double
    ) -> some View {
        let height = max(Self.chartHeight * ratio, 4)

        return VStack(spacing: 0) {
            Spacer(minLength: 0)

            switch month.state {
            case .closed:
                UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4)
                    .fill(Palette.gold)
                    .frame(height: height)

            case .current:
                UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4)
                    .fill(Palette.accent.opacity(.medium))
                    .frame(height: height)

            case .upcoming:
                UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4)
                    .fill(Palette.accent.opacity(.faint))
                    .frame(height: 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private extension ReviewProgressView {
    static let chartHeight: CGFloat = 96

    static func labelColor(of month: ReviewYearProgress.Month) -> Color {
        switch month.state {
        case .closed: Palette.subtext
        case .current: Palette.accent
        case .upcoming: Palette.subtext.opacity(.medium)
        }
    }
}
