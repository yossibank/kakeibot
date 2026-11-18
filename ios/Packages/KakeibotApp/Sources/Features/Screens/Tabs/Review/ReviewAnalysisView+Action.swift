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

    @ViewBuilder
    func action(
        _ summary: ReviewBreakdown.Summary,
        suggestion text: String
    ) -> some View {
        if let action = summary.action,
           summary.focus.amount > 0 {
            trial(action, amount: summary.focus.amount, current: "今")
        } else if let monthly = monthTrial {
            trial(monthly.action, amount: monthly.peak.amount, current: "\(monthly.peak.month)月")
        } else {
            suggestion(text)
        }
    }

    func rewriteButton(since date: Date?) -> some View {
        let hasNew = date != nil && newEntries > 0
        let title = hasNew ? "新しい記録で再分析" : "再分析する"
        let detail = hasNew ? "前回のあとに \(newEntries) 件増えました" : date.map(Self.lastText)

        return Button(action: onRewrite) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise")
                    .sansFont(.small, weight: .bold)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 36, height: 36)
                    .background(Palette.backgroundBottom.opacity(.strong), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .textFont(.subheadline, weight: .bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let detail {
                        Text(detail)
                            .textFont(.caption2)
                            .opacity(0.75)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer(minLength: 0)

                if hasNew {
                    Text("+\(newEntries) 件")
                        .textFont(.caption2, weight: .bold)
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Palette.backgroundBottom.opacity(.strong),
                            in: .rect(cornerRadius: 8)
                        )
                }
            }
            .foregroundStyle(Palette.backgroundBottom)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Palette.gold)
                    .overlay {
                        glint
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(.soft))
                    }
                    .shadow(color: Palette.accentDeep.opacity(.muted), radius: 10, y: 6)
            }
            .contentShape(.rect)
        }
        .buttonStyle(PressButtonStyle())
    }

    static func signed(_ amount: Int) -> String {
        if amount > 0 {
            return "+\(ReviewInsight.yen(amount))"
        }

        return amount < 0 ? "−\(ReviewInsight.yen(-amount))" : "±0円"
    }
}

private extension ReviewAnalysisView {
    var glint: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(.soft),
                    Color.white.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: proxy.size.width * 0.4)
            .keyframeAnimator(initialValue: CGFloat(-0.5), repeating: true) { view, value in
                view.offset(x: proxy.size.width * value)
            } keyframes: { _ in
                LinearKeyframe(-0.5, duration: 5)
                CubicKeyframe(1.2, duration: 2)
            }
        }
        .clipShape(.rect(cornerRadius: 16))
        .allowsHitTesting(false)
    }

    func trial(
        _ action: ReviewBreakdown.Action,
        amount: Int,
        current: String
    ) -> some View {
        let after = max(amount - action.amount, 0)
        let ratio = Double(after) / Double(amount)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("試算")
                    .textFont(.caption2, weight: .bold)
                    .tracking(1)
                    .foregroundStyle(Palette.backgroundBottom)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Palette.gold, in: .rect(cornerRadius: 8))

                Text(action.lead)
                    .textFont(.footnote, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                trialBar(
                    current,
                    amount: amount,
                    ratio: 1,
                    fill: AnyShapeStyle(Palette.accent.opacity(.soft))
                )

                trialBar(
                    "試算",
                    amount: after,
                    ratio: ratio,
                    fill: AnyShapeStyle(Palette.gold)
                )
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Spacer(minLength: 0)

                Text("浮く金額")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Text(ReviewInsight.yen(action.amount))
                    .displayFont(.title, weight: .bold)
                    .foregroundStyle(Palette.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .monospacedDigit()
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Palette.accent.opacity(.soft))
                    .frame(height: 1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.trialFill, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Palette.accent.opacity(.muted))
        }
        .shadow(color: Palette.accent.opacity(.subtle), radius: 12, y: 8)
    }

    func trialBar(
        _ title: String,
        amount: Int,
        ratio: Double,
        fill: AnyShapeStyle
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .frame(width: 32, alignment: .leading)

            Capsule()
                .fill(Palette.accent.opacity(.faint))
                .frame(height: 10)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(fill)
                            .frame(width: proxy.size.width * ratio * (hasAppeared ? 1 : 0))
                    }
                }

            Text(ReviewInsight.yen(amount))
                .sansFont(.caption, weight: .semibold)
                .foregroundStyle(Palette.text)
                .monospacedDigit()
                .fixedSize()
                .frame(minWidth: 64, alignment: .trailing)
        }
    }

    static func lastText(_ date: Date) -> String {
        let text = date.formatted(.dateTime.month(.defaultDigits).day().hour().minute())
        return "前回 \(text)"
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
}
