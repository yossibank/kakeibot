import DesignSystem
import SwiftUI

struct SettingsAmountButton: View {
    @Environment(\.themeStyle.corner) private var corner

    let amount: Int
    let text: String?
    let isEmpty: Bool
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(16), style: .continuous)

        Button(action: action) {
            HStack(spacing: 8) {
                value
                    .layoutPriority(1)

                Image(systemName: "pencil")
                    .sansFont(.micro, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Circle()
                            .stroke(Palette.outline, lineWidth: 1)
                    }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 56)
            .overlay {
                shape
                    .stroke(Palette.outline, style: stroke)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}

private extension SettingsAmountButton {
    var stroke: StrokeStyle {
        isEmpty ? .dashed : StrokeStyle(lineWidth: 1)
    }

    @ViewBuilder
    var value: some View {
        if let text {
            Text(text)
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        } else {
            SettingsKeypadValue(amount, isAnimated: false)
        }
    }
}
