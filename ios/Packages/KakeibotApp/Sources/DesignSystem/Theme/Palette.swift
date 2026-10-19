import SwiftUI

public enum Palette {}

public extension Palette {
    static let backgroundTop = Color(themed: \.backgroundTop)
    static let backgroundBottom = Color(themed: \.backgroundBottom)
    static let panel = Color(themed: \.panel)
    static let cardTop = Color(themed: \.cardTop)
    static let cardBottom = Color(themed: \.cardBottom)
    static let line = Color(themed: \.line)
    static let accent = Color(themed: \.accent)
    static let accentDeep = Color(themed: \.accentDeep)
    static let accentLight = Color(themed: \.accentLight)
    static let text = Color(themed: \.text)
    static let subtext = Color(themed: \.subtext)
    static let hint = Color(themed: \.hint)
    static let rose = Color(rgb: 0xE3A3A3)
    static let amber = Color(rgb: 0xE89B57)
    static let holiday = Color(rgb: 0xEE8A84)
    static let saturday = Color(rgb: 0x8DB0EA)
    static let hairline = accent.opacity(.subtle)
    static let outline = accent.opacity(.medium)
    static let faint = accent.opacity(.faint)

    static var background: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var card: LinearGradient {
        LinearGradient(
            colors: [cardTop, cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
