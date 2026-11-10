import Core
import DesignSystem
import SwiftUI

extension ReviewView {
    @ViewBuilder
    func upcomingRow(
        _ upcoming: Int,
        tapOutsets: EdgeInsets
    ) -> some View {
        if model.scale == .month {
            Button(action: onOpenRecurrings) {
                HStack(spacing: 4) {
                    upcomingLabel(upcoming)

                    Image(systemName: "chevron.right")
                        .sansFont(.micro, weight: .semibold)
                }
                .upcomingRowStyle()
                .tapArea(tapOutsets)
            }
            .buttonStyle(.plain)
        } else {
            upcomingLabel(upcoming)
                .upcomingRowStyle()
        }
    }
}

private extension ReviewView {
    func upcomingLabel(_ upcoming: Int) -> some View {
        let rest = "これからの固定費 \(AmountText.text(upcoming))"
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
        case .week: "週末の見込み"
        case .month: "月末の見込み"
        case .year: "年末の見込み"
        }
    }

    func outlookText(_ upcoming: Int) -> String {
        let total = model.total(of: model.kind) + upcoming
        return "\(Self.outlookName(of: model.scale)) \(AmountText.text(total))"
    }
}

private extension View {
    func upcomingRowStyle() -> some View {
        textFont(.caption)
            .monospacedDigit()
            .foregroundStyle(Palette.subtext)
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
    }
}
