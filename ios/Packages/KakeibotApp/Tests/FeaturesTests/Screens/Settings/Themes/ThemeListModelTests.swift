import Core
import FeatureModels
import Features
import Store
import Testing

@MainActor
struct ThemeListModelTests {
    @Test
    func startsFromSavedTheme() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.database.setSetting(.theme, to: .preset(.wine))
        let model = Self.model(database: setup.database)

        await model.load()

        #expect(model.input.current == .preset(.wine))
    }

    @Test
    func savesChosenTheme() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = Self.model(database: setup.database)

        await model.load()
        let initial = model.input.current
        await model.select(.preset(.forest))
        let saved = try await setup.database.setting(.theme)

        #expect(initial == .system)
        #expect(model.input.current == .preset(.forest))
        #expect(saved == .preset(.forest))
    }

    @Test
    func suggestsMatchingIcon() async throws {
        let setup = try await HomeModelTests.Setup()
        let switcher = AppIconListModelTests.Switcher(name: nil)
        let appIcon = AppIconListModel(switcher: switcher.client)
        let model = ThemeListModel(parts: .system(setup.database), appIcon: appIcon)

        await model.select(.preset(.sage))
        let suggested = model.state.suggestedIcon
        await model.use(suggested)

        #expect(suggested == .sage)
        #expect(model.state.suggestedIcon == nil)
        #expect(switcher.name == "AppIcon-Sage")
    }

    @Test
    func skipsSuggestionForSameIcon() async throws {
        let setup = try await HomeModelTests.Setup()
        let switcher = AppIconListModelTests.Switcher(name: "AppIcon-Wine")
        let appIcon = AppIconListModel(switcher: switcher.client)
        let model = ThemeListModel(parts: .system(setup.database), appIcon: appIcon)

        await model.select(.preset(.wine))

        #expect(model.state.suggestedIcon == nil)
    }
}

private extension ThemeListModelTests {
    static func model(database: AppDatabase) -> ThemeListModel {
        let switcher = AppIconListModelTests.Switcher(name: nil)
        let appIcon = AppIconListModel(switcher: switcher.client)
        return ThemeListModel(parts: .system(database), appIcon: appIcon)
    }
}
