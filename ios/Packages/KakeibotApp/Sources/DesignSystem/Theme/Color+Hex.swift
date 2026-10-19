import Core
import SwiftUI
import UIKit

public extension Color {
    init?(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex

        guard digits.count == 6, let value = UInt32(digits, radix: 16) else {
            return nil
        }

        self.init(rgb: value)
    }

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
}

extension Color {
    init(rgb value: UInt32) {
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    init(themed role: KeyPath<ThemePalette, UInt32> & Sendable) {
        let color = UIColor { traits in
            UIColor(rgb: traits[PaletteTrait.self][keyPath: role])
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
