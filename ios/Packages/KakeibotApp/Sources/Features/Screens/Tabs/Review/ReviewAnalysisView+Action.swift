import Core
import DesignSystem
import SwiftUI

extension ReviewAnalysisView {
    struct PressButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .brightness(configuration.isPressed ? -0.06 : 0)
                .animation(.snappy(duration: 0.15), value: configuration.isPressed)
        }
    }

    struct Trial {
        struct Term: Hashable {
            let title: String
            let value: String
        }

        let lead: String
        let name: String
        let before: Int
        let saved: Int
        let sign: String
        let terms: [Term]
        let kept: Int?
        let cut: Int
    }

    @ViewBuilder
    func action(
        _ summary: ReviewBreakdown.Summary,
        suggestion text: String
    ) -> some View {
        if let action = summary.action,
           summary.focus.amount > 0 {
            trial(savingTrial(summary.focus, action: action))
        } else if let monthly = monthTrial {
            trial(peakTrial(monthly))
        } else {
            suggestion(text)
        }
    }

    static func signed(_ amount: Int) -> String {
        if amount > 0 {
            return "+\(ReviewInsight.yen(amount))"
        }

        return amount < 0 ? "−\(ReviewInsight.yen(-amount))" : "±0円"
    }
}

private extension ReviewAnalysisView {
    func trial(_ trial: Trial) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("次の一手")
                    .textFont(.caption2, weight: .bold)
                    .tracking(1)
                    .foregroundStyle(Palette.backgroundBottom)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Palette.gold, in: .rect(cornerRadius: 8))
                    .fixedSize()

                Text(trial.lead)
                    .textFont(.footnote, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let kept = trial.kept {
                HStack(spacing: 8) {
                    dots(kept, base: kept, dashed: trial.cut)

                    Text("\(trial.cut) 回へらす")
                        .textFont(.caption, weight: .bold)
                        .foregroundStyle(Palette.accentStrong)
                        .fixedSize()
                }
            }

            formula(trial)

            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(trial.name)は")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)

                    Text(trial.change)
                        .textFont(.footnote, weight: .bold)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("浮く金額")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)

                    Text(ReviewInsight.yen(trial.saved))
                        .displayFont(.title, weight: .bold)
                        .foregroundStyle(Palette.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Palette.accent.opacity(.soft))
                    .frame(height: 1)
            }
        }
        .monospacedDigit()
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.trialFill, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Palette.accent.opacity(.muted))
        }
        .shadow(color: Palette.accent.opacity(.subtle), radius: 12, y: 8)
    }

    func formula(_ trial: Trial) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(trial.terms.enumerated()), id: \.offset) { index, term in
                formulaRow(
                    index == 0 ? "" : trial.sign,
                    title: term.title,
                    value: term.value
                )
            }

            Rectangle()
                .fill(Palette.accent.opacity(.soft))
                .frame(height: 1)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("＝")
                    .textFont(.footnote, weight: .bold)
                    .foregroundStyle(Palette.accent)

                Spacer(minLength: 8)

                Text(ReviewInsight.yen(trial.saved))
                    .textFont(.subheadline, weight: .bold)
                    .foregroundStyle(Palette.accentStrong)
            }
        }
        .padding(12)
        .background(Palette.accent.opacity(.faint), in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Palette.accent.opacity(.subtle))
        }
    }

    func formulaRow(
        _ sign: String,
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(sign)
                .textFont(.footnote, weight: .bold)
                .foregroundStyle(Palette.accent)
                .frame(width: 12, alignment: .leading)

            Text(title)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Text(value)
                .textFont(.footnote, weight: .bold)
                .foregroundStyle(Palette.text)
                .fixedSize()
        }
    }
}

private extension ReviewAnalysisView {
    static var trialFill: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.subtle), Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func savingTrial(
        _ focus: ReviewBreakdown.Focus,
        action: ReviewBreakdown.Action
    ) -> Trial {
        let cut = focus.count - focus.previousCount
        let isCount = cut > 0
        let hasDots = isCount && focus.count <= Self.maximumDots
        let price = ReviewInsight.yen(focus.unitPrice)
        let difference = focus.unitPrice - focus.previousUnitPrice
        let gap = Self.signed(difference)
        let saved = isCount ? cut * focus.unitPrice : difference * focus.count

        let countTerms = [
            Trial.Term(title: "へらす回数", value: "\(cut) 回"),
            Trial.Term(title: "\(currentName)の 1 回あたり", value: price)
        ]

        let priceTerms = [
            Trial.Term(title: "1 回の差", value: gap),
            Trial.Term(title: "\(currentName)の回数", value: "\(focus.count) 回")
        ]

        let terms = isCount ? countTerms : priceTerms

        return Trial(
            lead: action.lead,
            name: focus.name,
            before: focus.amount,
            saved: saved,
            sign: "×",
            terms: terms,
            kept: hasDots ? focus.previousCount : nil,
            cut: max(cut, 0)
        )
    }

    func peakTrial(_ monthly: MonthTrial) -> Trial {
        let month = "\(monthly.peak.month)月"

        let terms = [
            Trial.Term(title: month, value: ReviewInsight.yen(monthly.peak.amount)),
            Trial.Term(title: "月の平均", value: ReviewInsight.yen(monthly.average))
        ]

        return Trial(
            lead: monthly.action.lead,
            name: month,
            before: monthly.peak.amount,
            saved: monthly.action.amount,
            sign: "−",
            terms: terms,
            kept: nil,
            cut: 0
        )
    }
}

private extension ReviewAnalysisView.Trial {
    var change: String {
        let after = ReviewInsight.yen(before - saved)
        return "\(ReviewInsight.yen(before)) → \(after)"
    }
}
