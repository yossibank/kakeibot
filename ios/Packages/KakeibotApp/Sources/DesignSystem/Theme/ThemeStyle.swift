import Core
import CoreGraphics
import SwiftUI

public extension ThemeStyle {
    var bodyFont: Font {
        .text(.body, in: textFont, scale: textSize.scale)
    }
}

public extension ThemeCorner {
    func radius(_ base: CGFloat) -> CGFloat {
        (base * scale).rounded()
    }
}

public extension EnvironmentValues {
    @Entry var themeStyle = ThemeStyle.standard
}
