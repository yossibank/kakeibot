import DesignSystem
import SwiftUI

enum SettingsTileStyle {
    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func fill(isSelected: Bool) -> Color {
        isSelected ? Palette.lit.opacity(.subtle) : Color.clear
    }

    static func stroke(isSelected: Bool) -> Color {
        isSelected ? Palette.outline : Palette.accent.opacity(.subtle)
    }
}
