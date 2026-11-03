import Core
import DesignSystem
import SwiftUI
import Testing

@MainActor
struct PaletteTests {
    @Test
    func usesWhiteByDefault() {
        let environment = EnvironmentValues()
        let accent = Palette.accent.resolve(in: environment)
        #expect(rgb(accent) == ThemePreset.white.palette.accent)
    }

    @Test
    func followsTheme() {
        var environment = EnvironmentValues()
        environment.palette = Self.forest

        let accent = Palette.accent.resolve(in: environment)
        let text = Palette.text.resolve(in: environment)

        #expect(rgb(accent) == 0x7FD1A8)
        #expect(rgb(text) == 0xF0F5F2)
    }

    @Test
    func changesMeaningColorsByTheme() {
        var environment = EnvironmentValues()
        environment.palette = Self.forest

        let dark = Palette.rose.resolve(in: environment)

        environment.palette = ThemePreset.white.palette

        let light = Palette.rose.resolve(in: environment)

        #expect(rgb(dark) == 0xE3A3A3)
        #expect(rgb(light) == 0xB04A4A)
    }

    @Test
    func shiftsMeaningColorsOnMidtoneBackground() {
        var palette = Self.forest
        palette.backgroundTop = 0x7B7B5D
        palette.backgroundBottom = 0x7B7B5D
        palette.panel = 0x7B7B5D
        palette.cardTop = 0x7B7B5D
        palette.cardBottom = 0x7B7B5D

        var environment = EnvironmentValues()
        environment.palette = palette

        let rose = Palette.rose.resolve(in: environment)

        #expect(rgb(rose) == palette.color(.rose))
    }
}

private extension PaletteTests {
    static let forest = ThemePalette(
        backgroundTop: 0x143C32,
        backgroundBottom: 0x04130E,
        panel: 0x0B2620,
        cardTop: 0x12352C,
        cardBottom: 0x061712,
        line: 0x1F4A3E,
        accent: 0x7FD1A8,
        accentDeep: 0x3F7A5C,
        accentStrong: 0xD8F2E4,
        text: 0xF0F5F2,
        subtext: 0x8FB3A5,
        hint: 0x7A9C8F
    )

    func rgb(_ color: Color.Resolved) -> UInt32 {
        let components = [color.red, color.green, color.blue].map { value in
            UInt32((value * 255).rounded())
        }

        return components[0] << 16 | components[1] << 8 | components[2]
    }
}
