import DesignSystem
import SwiftUI

enum SettingsTile {
    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func fill(isSelected: Bool) -> Color {
        isSelected ? Palette.accent.opacity(.subtle) : Color.clear
    }

    static func stroke(isSelected: Bool) -> Color {
        isSelected ? Palette.outline : Palette.accent.opacity(.subtle)
    }
}
