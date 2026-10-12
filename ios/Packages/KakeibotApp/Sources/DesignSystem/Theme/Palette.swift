import SwiftUI

public enum Palette {}

public extension Palette {
    static let nightTop = rgb(0x16223D)
    static let nightBottom = rgb(0x080C16)
    static let gold = rgb(0xCDAA6B)
    static let champagne = rgb(0xF4E6C1)
    static let ink = rgb(0xEDE6D6)
    static let mist = rgb(0x8C97AE)
    static let dusk = rgb(0x7E89A0)
    static let line = rgb(0x26314A)

    static var night: LinearGradient {
        LinearGradient(
            colors: [nightTop, nightBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private extension Palette {
    static func rgb(_ value: UInt32) -> Color {
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        return Color(red: red, green: green, blue: blue)
    }
}
