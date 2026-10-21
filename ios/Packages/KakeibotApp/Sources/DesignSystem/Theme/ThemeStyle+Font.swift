import Core
import SwiftUI

public extension ThemeStyle {
    var bodyFont: Font {
        .text(.body, in: textFont, scale: textSize.scale)
    }
}
