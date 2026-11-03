import Core
import Foundation
import Testing

struct ThemePaletteContrastTests {
    @Test(arguments: try contrastCases)
    func measuresContrast(fixture: ContrastCase) {
        let first = Self.rgb(fixture.first)
        let second = Self.rgb(fixture.second)
        let ratio = ThemePalette.contrast(first, second)
        let roundedRatio = (ratio * 100).rounded() / 100
        #expect(roundedRatio == fixture.ratio)
    }

    @Test(arguments: try readableCases)
    func findsUnreadableRoles(fixture: ReadableCase) {
        let theme = Self.theme(fixture.theme)
        #expect(theme.unreadableRoles == fixture.unreadable)
    }

    @Test(arguments: ThemePreset.allCases)
    func keepsPresetsReadable(preset: ThemePreset) {
        #expect(preset.palette.unreadableRoles.isEmpty)
    }

    @Test
    func tellsLightBackground() {
        let light = ThemePreset.allCases.filter(\.palette.isLight)
        #expect(light == [.white, .ivory, .sky, .sage, .rose, .gold])
    }
}

extension ThemePaletteContrastTests {
    struct ContrastCase: Decodable, Sendable {
        let first: String
        let second: String
        let ratio: Double
    }

    struct ReadableCase: Decodable, Sendable {
        let theme: [String: String]
        let unreadable: [ThemePalette.Role]
    }
}

private extension ThemePaletteContrastTests {
    static var contrastCases: [ContrastCase] {
        get throws {
            try CoreFixture.cases("theme/theme-palette-contrast.json")
        }
    }

    static var readableCases: [ReadableCase] {
        get throws {
            try CoreFixture.cases("theme/theme-palette-readable.json")
        }
    }

    static func rgb(_ hex: String) -> UInt32 {
        let digits = hex.dropFirst()
        return UInt32(digits, radix: 16) ?? 0
    }

    static func theme(_ colors: [String: String]) -> ThemePalette {
        func color(_ role: ThemePalette.Role) -> UInt32 {
            rgb(colors[role.rawValue] ?? "")
        }

        let backgroundTop = color(.backgroundTop)
        let backgroundBottom = color(.backgroundBottom)
        let panel = color(.panel)
        let cardTop = color(.cardTop)
        let cardBottom = color(.cardBottom)
        let line = color(.line)
        let accent = color(.accent)
        let accentDeep = color(.accentDeep)
        let accentStrong = color(.accentStrong)
        let text = color(.text)
        let subtext = color(.subtext)
        let hint = color(.hint)

        return ThemePalette(
            backgroundTop: backgroundTop,
            backgroundBottom: backgroundBottom,
            panel: panel,
            cardTop: cardTop,
            cardBottom: cardBottom,
            line: line,
            accent: accent,
            accentDeep: accentDeep,
            accentStrong: accentStrong,
            text: text,
            subtext: subtext,
            hint: hint
        )
    }
}
