import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension ReviewClosingView {
    func specialCard(_ special: ReviewClosing.Special) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            specialHeader(special)

            specialFooter(special)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: ReviewReportRadius.panel)
                .fill(Self.specialGlow)
                .overlay {
                    RoundedRectangle(cornerRadius: ReviewReportRadius.panel)
                        .strokeBorder(Palette.amber.opacity(.muted))
                }
        }
    }
}

private extension ReviewClosingView {
    func specialHeader(_ special: ReviewClosing.Special) -> some View {
        let date = special.date.monthDayText

        return HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .sansFont(.small, weight: .bold)
                .foregroundStyle(Palette.cardBottom)
                .frame(width: 32, height: 32)
                .background(Self.specialFill, in: .rect(cornerRadius: ReviewReportRadius.block))

            VStack(alignment: .leading, spacing: 0) {
                Text("特別な支出")
                    .textFont(.caption2, weight: .bold)
                    .tracking(1.5)
                    .foregroundStyle(Palette.amber)

                Text(special.name)
                    .displayFont(style: .subheadline, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Text(date)
                .textFont(.caption2, weight: .bold)
                .foregroundStyle(Palette.amber)
                .monospacedDigit()
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .overlay {
                    Capsule()
                        .strokeBorder(Palette.amber.opacity(.medium))
                }
                .fixedSize()
        }
    }

    func specialFooter(_ special: ReviewClosing.Special) -> some View {
        let amount = ReviewYen.number(special.amount)

        return HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text("平均の計算から外しています")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(amount)
                    .displayFont(.headline, weight: .bold)
                    .monospacedDigit()

                Text("円")
                    .displayFont(.small, weight: .bold)
            }
            .foregroundStyle(Palette.amber)
            .fixedSize()
        }
        .padding(.top, 12)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.amber.opacity(.soft))
                .frame(height: 1)
        }
    }
}

private extension ReviewClosingView {
    static var specialFill: LinearGradient {
        LinearGradient(
            colors: [Palette.amber.opacity(.medium), Palette.amber],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var specialGlow: LinearGradient {
        LinearGradient(
            colors: [Palette.amber.opacity(.subtle), Palette.amber.opacity(.faint)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
