import SwiftUI
import UIKit

struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.night
}

extension ThemeKey: UITraitBridgedEnvironmentKey {
    static func read(from traitCollection: UITraitCollection) -> Theme {
        traitCollection[ThemeTrait.self]
    }

    static func write(
        to mutableTraits: inout UIMutableTraits,
        value: Theme
    ) {
        mutableTraits[ThemeTrait.self] = value
    }
}
