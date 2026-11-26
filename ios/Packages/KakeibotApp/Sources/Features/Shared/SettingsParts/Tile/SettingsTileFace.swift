import Core
import DesignSystem
import SwiftUI

private struct SettingsTileFace: ViewModifier {
    @Environment(\.themeStyle.corner) private var corner

    let isHidden: Bool

    func body(content: Content) -> some View {
        content
            .background {
                if !isHidden {
                    shape
                        .fill(SettingsTileStyle.cardFill)
                }
            }
            .overlay {
                border
            }
    }
}

private extension SettingsTileFace {
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

private extension SettingsTileFace {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }
}

extension View {
    func settingsTileFace(isHidden: Bool) -> some View {
        modifier(SettingsTileFace(isHidden: isHidden))
    }
}
