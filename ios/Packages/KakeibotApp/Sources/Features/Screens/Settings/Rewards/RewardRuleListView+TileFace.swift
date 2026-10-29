import Core
import DesignSystem
import Store
import SwiftUI

extension RewardRuleListView {
    func tileFace(
        _ rule: RewardRule,
        isHidden: Bool
    ) -> some View {
        let opacity: Double = isHidden ? 0.6 : 1
        let icon = model.icon(for: rule)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                IconBadge(icon, size: 46)

                Spacer(minLength: 6)

                if let total = model.total(for: rule) {
                    totalBadge(total)
                }
            }

            Text(rule.name)
                .textFont(.subheadline, weight: .semibold)
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("達成で")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                Text("+\(AmountText.text(rule.amount))")
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
            glow(icon)
        }
        .clipShape(tileShape)
        .settingsTileFace(isHidden: isHidden)
        .opacity(opacity)
        .contentShape(.rect)
    }
}

extension RewardRuleListView {
    var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }
}

private extension RewardRuleListView {
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

    func glow(_ icon: Icon?) -> some View {
        let color = icon.flatMap { Color(hex: $0.color) } ?? Palette.accent

        return Circle()
            .fill(color.opacity(0.18))
            .frame(width: 120, height: 120)
            .blur(radius: 24)
            .offset(x: 36, y: -36)
    }
}
