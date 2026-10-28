import DesignSystem
import SwiftUI

extension View {
    func settingsTileFace(isHidden: Bool) -> some View {
        modifier(SettingsTileFace(isHidden: isHidden))
    }
}

private struct SettingsTileFace: ViewModifier {
    @Environment(\.themeStyle.corner) private var corner

    let isHidden: Bool

    func body(content: Content) -> some View {
        content
            .background {
                if !isHidden {
                    shape
                        .fill(SettingsTile.cardFill)
                }
            }
            .overlay {
                border
            }
    }
}

private extension SettingsTileFace {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    @ViewBuilder
    var border: some View {
        if isHidden {
            shape
                .stroke(Palette.subtext.opacity(.muted), style: .dashed)
        } else {
            shape
                .stroke(Palette.accent.opacity(.soft), lineWidth: 1)
        }
    }
}
