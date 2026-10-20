import Core
import Foundation
import Testing

struct ThemePaletteContrastTests {
    @Test(arguments: try contrastCases)
    func measuresContrast(fixture: ContrastCase) {
        let ratio = ThemePalette.contrast(
            Self.rgb(fixture.first),
            Self.rgb(fixture.second)
        )

        #expect((ratio * 100).rounded() / 100 == fixture.ratio)
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

        #expect(light == [.ivory, .white, .sky, .sage, .rose, .gold])
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
            try Fixture.load("setting/theme-palette-contrast.json")
        }
    }

    static var readableCases: [ReadableCase] {
        get throws {
            try Fixture.load("setting/theme-palette-readable.json")
        }
    }

    static func rgb(_ hex: String) -> UInt32 {
        UInt32(hex.dropFirst(), radix: 16) ?? 0
    }

    static func theme(_ colors: [String: String]) -> ThemePalette {
        func color(_ role: ThemePalette.Role) -> UInt32 {
            rgb(colors[role.rawValue] ?? "")
        }

        return ThemePalette(
            backgroundTop: color(.backgroundTop),
            backgroundBottom: color(.backgroundBottom),
            panel: color(.panel),
            cardTop: color(.cardTop),
            cardBottom: color(.cardBottom),
            line: color(.line),
            accent: color(.accent),
            accentDeep: color(.accentDeep),
            accentStrong: color(.accentStrong),
            text: color(.text),
            subtext: color(.subtext),
            hint: color(.hint)
        )
    }
}
