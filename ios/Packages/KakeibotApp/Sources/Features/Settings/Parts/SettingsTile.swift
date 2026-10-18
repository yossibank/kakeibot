import DesignSystem
import SwiftUI

enum SettingsTile {}

extension SettingsTile {
    static func fill(isSelected: Bool) -> Color {
        isSelected ? Palette.gold.opacity(0.12) : Color.clear
    }

    static func stroke(isSelected: Bool) -> Color {
        isSelected ? Palette.outline : Palette.gold.opacity(0.12)
    }
}
