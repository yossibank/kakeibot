import Core
import SwiftUI
import UIKit

struct PaletteKey: EnvironmentKey {
    static let defaultValue = ThemePalette.night
}

extension PaletteKey: UITraitBridgedEnvironmentKey {
    static func read(from traitCollection: UITraitCollection) -> ThemePalette {
        traitCollection[PaletteTrait.self]
    }

    static func write(
        to mutableTraits: inout UIMutableTraits,
        value: ThemePalette
    ) {
        mutableTraits[PaletteTrait.self] = value
    }
}
