import Core
import DesignSystem
import Store
import SwiftUI

struct RewardRuleTile: View {
    @Environment(\.themeStyle.corner) private var corner

    let icon: Icon?
    let name: String
    let amount: Int
    let total: RewardRuleList.Total?
    let isHidden: Bool

    var body: some View {
        let opacity: Double = isHidden ? 0.6 : 1

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                IconBadge(icon, size: 46)

                Spacer(minLength: 8)

                if let total {
                    totalBadge(total)
                }
            }

            Text(name)
                .textFont(.subheadline, weight: .semibold)
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("達成で")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                Text("+\(AmountText.text(amount))")
                    .displayFont(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(alignment: .topTrailing) {
            glow
        }
        .clipShape(RoundedRectangle(cornerRadius: corner.radius(16)))
        .settingsTileFace(isHidden: isHidden)
        .opacity(opacity)
    }
}

private extension RewardRuleTile {
    var glow: some View {
        let color = icon.flatMap { Color(hex: $0.color) } ?? Palette.accent

        return Circle()
            .fill(color.opacity(0.18))
            .frame(width: 120, height: 120)
            .blur(radius: 24)
            .offset(x: 36, y: -36)
    }

    func totalBadge(_ total: RewardRuleList.Total) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("これまで \(total.count) 回")
                .textFont(.caption2, weight: .semibold)
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Palette.accent.opacity(.subtle), in: .capsule)

            Text("計 \(AmountText.text(total.amount))")
                .textFont(.caption2)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)
        }
    }
}
