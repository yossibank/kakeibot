import Core
import DesignSystem
import SwiftUI

extension ReviewView {
    @ViewBuilder
    func upcomingRow(
        _ upcoming: Int,
        tapOutsets: EdgeInsets,
        minHeight: CGFloat?
    ) -> some View {
        if model.scale == .month {
            Button(action: onOpenRecurrings) {
                HStack(spacing: 4) {
                    upcomingLabel(upcoming)

                    DisclosureMark(.link)
                }
                .upcomingRowStyle(minHeight: minHeight)
                .tapArea(tapOutsets)
            }
            .buttonStyle(.plain)
        } else {
            upcomingLabel(upcoming)
                .upcomingRowStyle(minHeight: minHeight)
        }
    }
}

private extension ReviewView {
    func upcomingLabel(_ upcoming: Int) -> some View {
        let rest = "固定費あと \(AmountText.text(upcoming))"
        let outlook = outlookText(upcoming)

        return Label {
            ViewThatFits(in: .horizontal) {
                Text("\(rest)・\(outlook)")
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(rest)
                    Text(outlook)
                }
            }
        } icon: {
            Image(systemName: "calendar")
        }
    }

    static func outlookName(of scale: ReviewPeriod.Scale) -> String {
        switch scale {
        case .week: "週末"
        case .month: "月末"
        case .year: "年末"
        }
    }

    func outlookText(_ upcoming: Int) -> String {
        let total = model.total(of: model.kind) + upcoming
        return "\(Self.outlookName(of: model.scale)) \(AmountText.text(total))"
    }
}

private extension View {
    func upcomingRowStyle(minHeight: CGFloat?) -> some View {
        textFont(.caption)
            .monospacedDigit()
            .foregroundStyle(Palette.subtext)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
    }
}
