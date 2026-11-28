import DesignSystem
import SwiftUI

struct ReviewReportStatTile: View {
    let title: String
    let systemImage: String
    let value: String
    let unit: String

    var note: String?
    var badge: String?
    var progress: Double?
    var color: Color = Palette.text

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 4) {
                    titleText

                    Spacer(minLength: 4)

                    Image(systemName: systemImage)
                        .sansFont(.small, weight: .semibold)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 24, height: 24)
                        .background(
                            Palette.lit.opacity(.subtle),
                            in: .rect(cornerRadius: ReviewReportRadius.chip)
                        )
                }

                titleText
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 24)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .displayFont(style: .title2, weight: .bold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(unit)
                    .textFont(.caption, weight: .bold)
                    .fixedSize()
            }
            .foregroundStyle(color)
            .frame(height: Self.valueHeight, alignment: .bottomLeading)

            detail
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.lit.opacity(.faint))
        .background(Palette.cardBottom)
    }
}

private extension ReviewReportStatTile {
    var titleText: some View {
        Text(title)
            .textFont(.caption2)
            .foregroundStyle(Palette.subtext)
            .lineLimit(1)
    }

    @ViewBuilder
    var detail: some View {
        if let progress {
            let clamped = min(max(progress, 0), 1)

            Capsule()
                .fill(Palette.lit.opacity(.subtle))
                .frame(height: 4)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Palette.gold)
                            .frame(width: proxy.size.width * clamped)
                    }
                }
                .padding(.top, 8)
        } else {
            HStack(spacing: 4) {
                if let badge {
                    Text(badge)
                        .textFont(.caption2, weight: .bold)
                        .foregroundStyle(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 1)
                        .background(color.opacity(.subtle), in: Capsule())
                        .fixedSize()
                }

                if let note {
                    Text(note)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private extension ReviewReportStatTile {
    static let valueHeight: CGFloat = 30
}
