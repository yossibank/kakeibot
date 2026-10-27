import Core
import Foundation
import Testing

struct ThemePaletteSemanticTests {
    @Test(arguments: try semanticCases)
    func makesReadableColor(fixture: SemanticCase) throws {
        let background = try #require(UInt32(fixture.background.dropFirst(), radix: 16))
        let palette = Self.palette(background: background)
        let semantic = try #require(ThemePalette.Semantic(rawValue: fixture.semantic))
        let color = palette.color(semantic)
        let base = palette.isLight ? semantic.light : semantic.dark

        if let expected = fixture.color {
            #expect(color == UInt32(expected.dropFirst(), radix: 16))
        } else {
            #expect(color != base)
            #expect(ThemePalette.contrast(color, background) >= 3)
        }
    }

    @Test(arguments: ThemePreset.allCases)
    func keepsPresetColors(preset: ThemePreset) {
        let palette = preset.palette

        for semantic in ThemePalette.Semantic.allCases {
            let base = palette.isLight ? semantic.light : semantic.dark

            #expect(palette.color(semantic) == base)
        }
    }
}

extension ThemePaletteSemanticTests {
    struct SemanticCase: Decodable, Sendable {
        let background: String
        let semantic: String
        let color: String?
    }
}

private extension ThemePaletteSemanticTests {
    static var semanticCases: [SemanticCase] {
        get throws {
            try Fixture.cases("setting/theme-palette-semantic.json")
        }
    }

    static func palette(background: UInt32) -> ThemePalette {
        var palette = ThemePalette.night
        palette.backgroundTop = background
        palette.backgroundBottom = background
        palette.panel = background
        palette.cardTop = background
        palette.cardBottom = background
        return palette
    }
}
