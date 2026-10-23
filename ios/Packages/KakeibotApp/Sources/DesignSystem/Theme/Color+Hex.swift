import Core
import SwiftUI
import UIKit

public extension Color {
    var hex: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let values = [red, green, blue].map { value in
            Int((min(max(value, 0), 1) * 255).rounded())
        }

        return "#" + values.map { String(format: "%02X", $0) }.joined()
    }

    init?(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex

        guard digits.count == 6, let value = UInt32(digits, radix: 16) else {
            return nil
        }

        self.init(rgb: value)
    }
}

extension Color {
    init(rgb value: UInt32) {
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }

    init(
        light: UInt32,
        dark: UInt32
    ) {
        let color = UIColor { traits in
            let isLight = traits.userInterfaceStyle == .light

            return UIColor(rgb: isLight ? light : dark)
        }

        self.init(uiColor: color)
    }

    init(
        themed role: KeyPath<ThemePalette, UInt32> & Sendable,
        lightOpacity: CGFloat = 1
    ) {
        let color = UIColor { traits in
            let rgb = traits[PaletteTrait.self][keyPath: role]
            let isLight = traits.userInterfaceStyle == .light
            let alpha = isLight ? lightOpacity : 1

            return UIColor(rgb: rgb).withAlphaComponent(alpha)
        }

        self.init(uiColor: color)
    }

    init(
        rgb value: UInt32,
        lightOpacity: CGFloat
    ) {
        let color = UIColor { traits in
            let isLight = traits.userInterfaceStyle == .light
            let alpha = isLight ? lightOpacity : 1

            return UIColor(rgb: value).withAlphaComponent(alpha)
        }

        self.init(uiColor: color)
    }
}

extension UIColor {
    convenience init(rgb value: UInt32) {
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
