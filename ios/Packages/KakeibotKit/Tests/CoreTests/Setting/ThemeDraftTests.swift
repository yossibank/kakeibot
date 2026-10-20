import Core
import Foundation
import Testing

struct ThemeDraftTests {
    @Test(arguments: try baseCases)
    func makesPaletteFromBaseColors(fixture: BaseCase) {
        let draft = ThemeDraft(
            name: "テーマ",
            background: fixture.background,
            surface: fixture.surface,
            text: fixture.text,
            subtext: fixture.subtext,
            accent: fixture.accent
        )

        let palette = draft.palette.map(Self.colors)

        #expect(palette == fixture.palette)
    }

    @Test(arguments: try draftCases)
    func findsProblems(fixture: DraftCase) {
        let draft = ThemeDraft(
            name: fixture.name,
            background: fixture.background,
            surface: fixture.surface,
            text: fixture.text,
            subtext: fixture.subtext,
            accent: fixture.accent
        )

        #expect(draft.problems == fixture.problems)
    }

    @Test(arguments: ThemePreset.allCases)
    func keepsPresetColorsAsDraft(preset: ThemePreset) {
        let draft = ThemeDraft(name: preset.title, palette: preset.palette)

        #expect(draft.palette?.backgroundTop == preset.palette.backgroundTop)
        #expect(draft.palette?.accent == preset.palette.accent)
    }

    @Test
    func keepsStyleInTheme() throws {
        let style = ThemeStyle(corner: .small, font: .gothic)
        let draft = ThemeDraft(
            name: "テーマ",
            palette: ThemePreset.navy.palette,
            style: style
        )

        let theme = try draft.newTheme(at: Date())

        #expect(theme.style == style)
    }

    @Test
    func readsUnknownStyleAsStandard() throws {
        let draft = ThemeDraft(name: "テーマ", palette: ThemePreset.navy.palette)
        var theme = try draft.newTheme(at: Date())
        theme.cornerRadius = 16
        theme.fontId = "system"

        #expect(theme.style == .standard)
    }
}

extension ThemeDraftTests {
    struct BaseCase: Decodable, Sendable {
        let background: String
        let surface: String
        let text: String
        let subtext: String
        let accent: String
        let palette: [String: String]
    }

    struct DraftCase: Decodable, Sendable {
        let name: String
        let background: String
        let surface: String
        let text: String
        let subtext: String
        let accent: String
        let problems: [DraftProblem]
    }
}

private extension ThemeDraftTests {
    static var baseCases: [BaseCase] {
        get throws {
            try Fixture.load("setting/theme-palette-base.json")
        }
    }

    static var draftCases: [DraftCase] {
        get throws {
            try Fixture.load("setting/theme-draft.json")
        }
    }

    static func colors(_ palette: ThemePalette) -> [String: String] {
        let pairs = ThemePalette.Role.allCases.map { role in
            let digits = String(palette[role], radix: 16, uppercase: true)
            let padding = String(repeating: "0", count: 6 - digits.count)
            return (role.rawValue, "#" + padding + digits)
        }

        return Dictionary(uniqueKeysWithValues: pairs)
    }
}
