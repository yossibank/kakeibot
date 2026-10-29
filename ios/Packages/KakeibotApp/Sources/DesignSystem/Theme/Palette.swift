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
    public static let rose = Color(semantic: .rose)
    public static let amber = Color(semantic: .amber)
    public static let holiday = Color(semantic: .holiday)
    public static let saturday = Color(semantic: .saturday)
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

public extension EnvironmentValues {
    var palette: ThemePalette {
        get {
            self[PaletteKey.self]
        }
        set {
            self[PaletteKey.self] = newValue
        }
    }
}
