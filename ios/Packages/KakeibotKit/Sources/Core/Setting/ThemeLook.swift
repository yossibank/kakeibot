public enum ThemeLook: Hashable, Sendable {
    case fixed(ThemePalette)
    case system(light: ThemePalette, dark: ThemePalette)
}

public extension ThemeLook {
    static let followsDevice = ThemeLook.system(
        light: ThemePreset.white.palette,
        dark: ThemePreset.black.palette
    )

    func palette(isDark: Bool) -> ThemePalette {
        switch self {
        case let .fixed(palette): palette
        case let .system(light, dark): isDark ? dark : light
        }
    }
}
