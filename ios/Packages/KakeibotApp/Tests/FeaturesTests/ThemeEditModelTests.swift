import Core
import Features
import Store
import Testing

@MainActor
struct ThemeEditModelTests {
    @Test
    func choosesNewTheme() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeEditModel(
            database: setup.database,
            editing: nil,
            base: ThemePreset.forest.palette
        )
        model.draft.name = "森の夜"

        let isSaved = await model.save()
        let themes = try await setup.database.customThemes()
        let choice = try await setup.database.setting(.theme)

        #expect(isSaved)
        #expect(themes.map(\.name) == ["森の夜"])
        #expect(choice == themes.first.map { .custom($0.id) })
    }

    @Test
    func blocksUnreadableColors() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeEditModel(
            database: setup.database,
            editing: nil,
            base: .night
        )
        model.draft.name = "読めない"
        model.draft.text = model.draft.background

        #expect(!model.canSave)
        #expect(model.saveTitle == "文字が読みにくい色です")
    }
}
