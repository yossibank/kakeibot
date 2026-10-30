import DesignSystem
import SwiftUI

struct AssetsGoalCard: View {
    let name: String
    let targetAmount: Int
    let remaining: Int
    let progress: Double
    var onBuy: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)
                    .sharedTextScale()

                Spacer(minLength: 8)

                Text(AmountText.text(targetAmount))
                    .textFont(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            RatioBar(progress, tint: Palette.accent, height: 8)

            HStack {
                if remaining > 0 || targetAmount == 0 {
                    Text("あと \(AmountText.text(remaining))")
                        .textFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accent)
                } else {
                    Text("届きました")
                        .textFont(.caption, weight: .semibold)
                        .foregroundStyle(Palette.accent)
                }

                Spacer()

                if remaining == 0,
                   targetAmount > 0,
                   let onBuy {
                    Button(action: onBuy) {
                        Text("買った")
                            .textFont(.caption, weight: .semibold)
                            .foregroundStyle(Palette.background)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Palette.accent, in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .card()
    }
}
