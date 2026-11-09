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
    static let planTitleIdealWidth: CGFloat = 48
}

private extension AssetsView {
    var planTexts: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("予定を含めると")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .fixedSize()

            if let first = model.plans.first {
                HStack(spacing: 4) {
                    Text("\(first.date.monthDayText) \(first.title)")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(
                            minWidth: 0,
                            idealWidth: Self.planTitleIdealWidth,
                            alignment: .leading
                        )

                    Text(planNote(first))
                        .fixedSize()
                }
                .textFont(.caption2)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
            }
        }
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

    func planNote(_ first: AssetsModel.Plan) -> String {
        let amount = AmountText.text(first.change, sign: .plus)
        let others = model.plans.count - 1
        return others > 0 ? "\(amount) ほか \(others) 件" : amount
    }
}
