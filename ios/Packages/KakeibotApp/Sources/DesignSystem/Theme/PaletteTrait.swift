import Core
import UIKit

struct PaletteTrait: UITraitDefinition {
    static let defaultValue = ThemePreset.white.palette
    static let affectsColorAppearance = true
}
