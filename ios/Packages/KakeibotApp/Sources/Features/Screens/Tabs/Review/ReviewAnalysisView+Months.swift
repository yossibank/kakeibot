import Core
import DesignSystem
import SwiftUI

extension ReviewAnalysisView {
    struct MonthTrial {
        let action: ReviewBreakdown.Action
        let peak: ReviewModel.MonthAmount
        let average: Int
    }

    var monthTrial: MonthTrial? {
        let used = months.filter { $0.amount > 0 }

        guard
            used.count >= 2,
            let peak = used.max(by: { $0.amount < $1.amount })
        else {
            return nil
        }

        let average = used.map(\.amount).reduce(0, +) / used.count
        let saved = peak.amount - average

        guard saved >= 100 else {
            return nil
        }

        let lead = "いちばん多い \(peak.month)月を、月の平均の \(ReviewInsight.yen(average)) ほどにすると"
        let action = ReviewBreakdown.Action(lead: lead, amount: saved)

        return MonthTrial(
            action: action,
            peak: peak,
            average: average
        )
    }

    func monthChart(_ name: String) -> some View {
        let top = max(months.map(\.amount).max() ?? 1, 1)
        let used = months.filter { $0.amount > 0 }
        let average = used.isEmpty ? 0 : used.map(\.amount).reduce(0, +) / used.count
        let peak = used.max { $0.amount < $1.amount }
        let line = Self.monthHeight * (1 - CGFloat(average) / CGFloat(top))

        return panel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    panelTitle("月ごとの\(name)")

                    Spacer(minLength: 8)

                    Text("平均 \(ReviewInsight.yen(average))")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Button {
                    onOpen(.current)
                } label: {
                    VStack(spacing: 8) {
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(months, id: \.self) { month in
                                monthBar(month, top: top, isPeak: month == peak)
                            }
                        }
                        .frame(height: Self.monthHeight)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Palette.accent.opacity(.medium))
                                .frame(height: 1)
                                .offset(y: line)
                                .opacity(average > 0 ? 1 : 0)
                        }

                        HStack(spacing: 4) {
                            ForEach(months, id: \.self) { month in
                                Text("\(month.month)")
                                    .sansFont(.micro)
                                    .foregroundStyle(month == peak
                                        ? Palette.accentStrong
                                        : Palette.subtext)
                                        .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(PressButtonStyle())
            }
        }
    }
}

private extension ReviewAnalysisView {
    static let monthHeight: CGFloat = 120

    func monthBar(
        _ month: ReviewModel.MonthAmount,
        top: Int,
        isPeak: Bool
    ) -> some View {
        let height = Self.monthHeight * CGFloat(month.amount) / CGFloat(top)
        let fill = isPeak
            ? AnyShapeStyle(Palette.gold)
            : AnyShapeStyle(Palette.accent.opacity(.muted))

        return RoundedRectangle(cornerRadius: 4)
            .fill(fill)
            .frame(height: max(height, month.amount > 0 ? 3 : 0))
            .shadow(color: Palette.accent.opacity(isPeak ? 0.2 : 0), radius: 4)
            .scaleEffect(y: hasAppeared ? 1 : 0.02, anchor: .bottom)
            .frame(maxWidth: .infinity)
    }
}
