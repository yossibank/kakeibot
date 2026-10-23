import Core
import SwiftUI

public enum Palette {
    public static let backgroundTop = Color(themed: \.backgroundTop)
    public static let backgroundBottom = Color(themed: \.backgroundBottom)
    public static let panel = Color(themed: \.panel)
    public static let cardTop = Color(themed: \.cardTop)
    public static let cardBottom = Color(themed: \.cardBottom)
    public static let line = Color(themed: \.line)
    public static let accent = Color(themed: \.accent)
    public static let accentDeep = Color(themed: \.accentDeep)
    public static let accentStrong = Color(themed: \.accentStrong)
    public static let text = Color(themed: \.text)
    public static let subtext = Color(themed: \.subtext)
    public static let hint = Color(themed: \.hint)
    public static let rose = Color(light: 0xB04A4A, dark: 0xE3A3A3)
    public static let amber = Color(light: 0xA8581A, dark: 0xE89B57)
    public static let holiday = Color(light: 0xC0392B, dark: 0xEE8A84)
    public static let saturday = Color(light: 0x2D63B5, dark: 0x8DB0EA)
    public static let shadow = Color(rgb: 0x000000, lightOpacity: 0.18)
    public static let scrim = Color(rgb: 0x000000, lightOpacity: 0.4)
    public static let glow = Color(themed: \.accent, lightOpacity: 0.4)
    public static let hairline = accent.opacity(.subtle)
    public static let outline = accent.opacity(.medium)
    public static let faint = accent.opacity(.faint)

    public static var background: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public static var card: LinearGradient {
        LinearGradient(
            colors: [cardTop, cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static func background(of palette: ThemePalette) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(rgb: palette.backgroundTop),
                Color(rgb: palette.backgroundBottom)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
