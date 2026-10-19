import DesignSystem
import SwiftUI

enum SettingsTile {}

extension SettingsTile {
    static func fill(isSelected: Bool) -> Color {
        isSelected ? Palette.accent.opacity(.subtle) : Color.clear
    }

    static func stroke(isSelected: Bool) -> Color {
        isSelected ? Palette.outline : Palette.accent.opacity(.subtle)
    }
}
