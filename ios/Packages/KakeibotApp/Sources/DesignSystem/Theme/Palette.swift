import SwiftUI

public enum Palette {}

public extension Palette {
    static let nightTop = Color(rgb: 0x16223D)
    static let nightBottom = Color(rgb: 0x080C16)
    static let gold = Color(rgb: 0xCDAA6B)
    static let champagne = Color(rgb: 0xF4E6C1)
    static let ink = Color(rgb: 0xEDE6D6)
    static let mist = Color(rgb: 0x8C97AE)
    static let dusk = Color(rgb: 0x7E89A0)
    static let line = Color(rgb: 0x26314A)

    static var night: LinearGradient {
        LinearGradient(
            colors: [nightTop, nightBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
