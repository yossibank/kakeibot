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
        let model = ThemeListModel(database: setup.database)

        await model.load()

        #expect(model.current == .wine)
    }

    @Test
    func savesChosenTheme() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeListModel(database: setup.database)

        await model.load()
        let initial = model.current
        await model.select(.forest)
        let saved = try await setup.database.setting(.theme)

        #expect(initial == .navy)
        #expect(model.current == .forest)
        #expect(saved == .forest)
    }
}
