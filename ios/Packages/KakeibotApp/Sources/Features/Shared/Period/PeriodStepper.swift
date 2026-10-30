import DesignSystem
import SwiftUI

struct PeriodStepper: View {
    let title: String
    let subtitle: String?
    let currentTitle: String?
    let transition: ContentTransition
    let canMoveForward: Bool
    let onMove: (Int) -> Void
    let onCurrent: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            arrow(systemImage: "chevron.left", count: -1)

            Spacer(minLength: 4)

            VStack(spacing: 1) {
                Text(title)
                    .displayFont(.body)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(transition)

                HStack(spacing: 4) {
                    if let subtitle {
                        Text(subtitle)
                            .textFont(size: .caption)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .contentTransition(transition)
                    }

                    if let currentTitle {
                        PeriodCurrentLink(title: currentTitle, action: onCurrent)
                    }
                }
            }

            Spacer(minLength: 4)

            arrow(systemImage: "chevron.right", count: 1)
                .disabled(!canMoveForward)
        }
    }
}

private extension PeriodStepper {
    func arrow(
        systemImage: String,
        count: Int
    ) -> some View {
        Button {
            onMove(count)
        } label: {
            Image(systemName: systemImage)
                .sansFont(.small, weight: .semibold)
                .foregroundStyle(Palette.subtext)
                .frame(width: 40, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
