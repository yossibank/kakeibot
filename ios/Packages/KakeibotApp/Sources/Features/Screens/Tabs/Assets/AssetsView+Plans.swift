import Core
import DesignSystem
import SwiftUI

extension AssetsView {
    var planButton: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(12))

        return Button {
            isShowingPlans = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .sansFont(.small)
                    .foregroundStyle(Palette.accent)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        planTexts

                        Spacer(minLength: 0)

                        planAmount
                            .fixedSize()
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        planTexts

                        planAmount
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image(systemName: "chevron.right")
                    .sansFont(.small)
                    .foregroundStyle(Palette.hint)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(Palette.faint, in: shape)
            .overlay {
                shape.stroke(Palette.accent.opacity(.muted), style: .dashed)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}

private extension AssetsView {
    var planTexts: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("予定を含めると")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Text("\(model.plans.count) 件の予定")
                .textFont(.caption2)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
        }
        .lineLimit(1)
        .fixedSize()
    }

    var planAmount: some View {
        AmountText(
            model.plannedTotal,
            font: .size(.headline),
            color: Palette.accentStrong
        )
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}
