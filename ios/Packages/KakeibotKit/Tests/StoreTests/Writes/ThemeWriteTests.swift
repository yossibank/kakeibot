import Core
import Foundation
import Store
import Testing

struct ThemeWriteTests {
    @Test
    func usesChosenCustomTheme() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 0)

        let theme = try await database.saveTheme(Self.mint, at: now)
        try await database.setSetting(.theme, to: .custom(theme.id))
        let look = try await database.themeLook()
        let palette = try #require(Self.mint.palette)

        #expect(look == .fixed(palette))
    }

    @Test
    func followsDeviceByDefault() async throws {
        let database = try AppDatabase.inMemory()

        let look = try await database.themeLook()

        #expect(look == .followsDevice)
    }

    @Test
    func savesFollowingDevice() async throws {
        let database = try AppDatabase.inMemory()

        try await database.setSetting(.theme, to: .preset(.black))
        try await database.setSetting(.theme, to: .system)
        let choice = try await database.setting(.theme)
        let look = try await database.themeLook()

        #expect(choice == .system)
        #expect(look == .followsDevice)
    }

    @Test
    func readsChosenStyle() async throws {
        let database = try AppDatabase.inMemory()

        try await database.setSetting(.cornerStyle, to: .large)
        try await database.setSetting(.fontStyle, to: .rounded)
        try await database.setSetting(.textFontStyle, to: .mincho)
        let style = try await database.style()

        let expected = ThemeStyle(
            corner: .large,
            displayFont: .rounded,
            textFont: .mincho
        )

        #expect(style == expected)
    }

    @Test
    func usesStandardStyleByDefault() async throws {
        let database = try AppDatabase.inMemory()

        let style = try await database.style()

        #expect(style == .standard)
    }

    @Test
    func updatesTheme() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 0)
        let theme = try await database.saveTheme(Self.mint, at: now)
        var draft = Self.mint
        draft.name = "夜のミント"

        let updated = try await database.saveTheme(
            draft,
            editing: theme.id,
            at: now.addingTimeInterval(60)
        )

        let themes = try await database.customThemes()

        #expect(updated.id == theme.id)
        #expect(themes.map(\.name) == ["夜のミント"])
    }

    @Test
    func returnsToWhiteAfterDeletingChosenTheme() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 0)
        let theme = try await database.saveTheme(Self.mint, at: now)
        try await database.setSetting(.theme, to: .custom(theme.id))

        try await database.deleteTheme(theme.id)
        let choice = try await database.setting(.theme)
        let themes = try await database.customThemes()

        #expect(choice == .preset(.white))
        #expect(themes.isEmpty)
    }

    @Test
    func rejectsUnreadableTheme() async throws {
        let database = try AppDatabase.inMemory()
        var draft = Self.mint
        draft.text = draft.background

        await #expect(throws: DraftProblem.unreadableColors) {
            try await database.saveTheme(draft, at: Date())
        }
    }
}

private extension ThemeWriteTests {
    static let mint = ThemeDraft(
        name: "ミント",
        background: "#12302C",
        surface: "#173A35",
        text: "#EAF4F1",
        subtext: "#8FB3A9",
        accent: "#7FD1B9"
    )
}
