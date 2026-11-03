import Core
import Foundation
import GRDB

public extension SettingKey where Value == ThemeChoice {
    static var theme: Self {
        Self(
            .themeId,
            default: .system,
            decode: { ThemeChoice($0) },
            encode: { $0.text }
        )
    }
}

public extension SettingKey where Value == ThemeCorner {
    static var cornerStyle: Self {
        Self(.cornerStyle, default: .standard)
    }
}

public extension SettingKey where Value == ThemeFont {
    static var fontStyle: Self {
        Self(.fontStyle, default: .mincho)
    }

    static var textFontStyle: Self {
        Self(.textFontStyle, default: .gothic)
    }
}

public extension SettingKey where Value == ThemeTextSize {
    static var textSize: Self {
        Self(.textSize, default: .standard)
    }
}

public extension SettingKey where Value == ThemeRowSpacing {
    static var rowSpacing: Self {
        Self(.rowSpacing, default: .standard)
    }
}

public extension SettingKey where Value == ThemeStampShape {
    static var stampShape: Self {
        Self(.stampShape, default: .circle)
    }
}

public extension SettingKey where Value == ThemeBackdrop {
    static var backdrop: Self {
        Self(
            .backdrop,
            default: .plain,
            decode: { text in
                ThemeBackdrop(rawValue: text) ?? (text == "washi" ? .ruled : nil)
            },
            encode: { $0.rawValue }
        )
    }
}
