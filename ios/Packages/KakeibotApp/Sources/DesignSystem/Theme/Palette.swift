import SwiftUI

public enum Palette {}

public extension Palette {
    static let nightTop = Color(rgb: 0x16223D)
    static let nightBottom = Color(rgb: 0x080C16)
    static let gold = Color(rgb: 0xCDAA6B)
    static let bronze = Color(rgb: 0x8F6C38)
    static let champagne = Color(rgb: 0xF4E6C1)
    static let ink = Color(rgb: 0xEDE6D6)
    static let mist = Color(rgb: 0x8C97AE)
    static let dusk = Color(rgb: 0x7E89A0)
    static let line = Color(rgb: 0x26314A)
    static let drawer = Color(rgb: 0x0E1628)
    static let cardTop = Color(rgb: 0x141C2F)
    static let cardBottom = Color(rgb: 0x090D18)
    static let rose = Color(rgb: 0xE3A3A3)
    static let holiday = Color(rgb: 0xEE8A84)
    static let saturday = Color(rgb: 0x8DB0EA)

    static var night: LinearGradient {
        LinearGradient(
            colors: [nightTop, nightBottom],
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
