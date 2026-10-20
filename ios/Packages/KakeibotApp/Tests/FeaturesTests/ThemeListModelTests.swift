import Core
import Features
import Store
import Testing

@MainActor
struct ThemeListModelTests {
    @Test
    func startsFromSavedTheme() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.database.setSetting(.theme, to: .wine)
        let model = Self.model(database: setup.database)

        await model.load()

        #expect(model.current == .wine)
    }

    @Test
    func savesChosenTheme() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = Self.model(database: setup.database)

        await model.load()
        let initial = model.current
        await model.select(.forest)
        let saved = try await setup.database.setting(.theme)

        #expect(initial == .navy)
        #expect(model.current == .forest)
        #expect(saved == .forest)
    }

    @Test
    func suggestsMatchingIcon() async throws {
        let setup = try await HomeModelTests.Setup()
        let switcher = AppIconListModelTests.Switcher(name: nil)
        let appIcon = AppIconListModel(switcher: switcher.client)
        let model = ThemeListModel(database: setup.database, appIcon: appIcon)

        await model.select(.sage)
        let suggested = model.suggestedIcon
        await model.use(suggested)

        #expect(suggested == .sage)
        #expect(model.suggestedIcon == nil)
        #expect(switcher.name == "AppIcon-Sage")
    }

    @Test
    func skipsSuggestionForSameIcon() async throws {
        let setup = try await HomeModelTests.Setup()
        let switcher = AppIconListModelTests.Switcher(name: "AppIcon-Wine")
        let appIcon = AppIconListModel(switcher: switcher.client)
        let model = ThemeListModel(database: setup.database, appIcon: appIcon)

        await model.select(.wine)

        #expect(model.suggestedIcon == nil)
    }
}

private extension ThemeListModelTests {
    static func model(database: AppDatabase) -> ThemeListModel {
        let switcher = AppIconListModelTests.Switcher(name: nil)
        let appIcon = AppIconListModel(switcher: switcher.client)
        return ThemeListModel(database: database, appIcon: appIcon)
    }
}
