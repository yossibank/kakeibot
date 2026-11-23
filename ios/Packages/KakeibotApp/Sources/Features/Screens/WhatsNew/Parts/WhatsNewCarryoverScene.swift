import Core
import DesignSystem
import SwiftUI

struct WhatsNewCarryoverScene: View {
    let step: Step

    var body: some View {
        switch step {
        case .toggle:
            toggle

        case .left:
            left

        case .next:
            next
        }
    }
}

extension WhatsNewCarryoverScene {
    enum Step: Hashable, Sendable {
        case toggle
        case left
        case next
    }
}

private extension WhatsNewCarryoverScene {
    var toggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("予算")
                .textFont(size: .micro, weight: .semibold)
                .tracking(1)
                .foregroundStyle(Palette.accent)

            HStack {
                Text("残りを\n繰り越す")
                    .textFont(size: .caption)
                    .foregroundStyle(Palette.text)

                Spacer(minLength: 4)

                Capsule()
                    .fill(Palette.accent)
                    .frame(width: 40, height: 24)
                    .overlay(alignment: .trailing) {
                        Circle()
                            .fill(.white)
                            .shadow(color: Palette.shadow, radius: 1, y: 1)
                            .padding(2)
                    }
            }
        }
        .padding(12)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var left: some View {
        VStack(spacing: 4) {
            Text("11月の残り")
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            ZStack(alignment: .bottom) {
                HalfDial(progress: 0.84)

                AmountText(
                    FeatureArtSample.carryover,
                    font: .size(.body, weight: .bold),
                    color: Palette.accentStrong
                )
            }
            .frame(width: 120, height: 60)
        }
    }

    var next: some View {
        let total = FeatureArtSample.budget + FeatureArtSample.carryover

        return VStack(alignment: .leading, spacing: 4) {
            Text("12月")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.accent)

            Text("予算 \(Yen.text(FeatureArtSample.budget))")
                .textFont(size: .caption)
                .foregroundStyle(Palette.text)

            Text("＋ 繰越 \(Yen.text(FeatureArtSample.carryover))")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.accentStrong)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Palette.accent.opacity(.subtle), in: .capsule)

            AmountText(total, font: .size(.headline, weight: .bold), color: Palette.accentStrong)
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}
