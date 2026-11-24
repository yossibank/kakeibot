import Core
@testable import FeatureModels
@testable import Features
import Store
import Testing

@MainActor
struct ThemeEditModelTests {
    @Test
    func choosesNewTheme() async throws {
        let setup = try await HomeModelTests.Setup()

        let model = ThemeEditModel(
            parts: .system(setup.database),
            editing: nil,
            base: ThemePreset.forest.palette
        )

        model.state.draft.name = "森の夜"

        let isSaved = await model.save()
        let themes = try await setup.database.customThemes()
        let choice = try await setup.database.setting(.theme)

        #expect(isSaved)
        #expect(themes.map(\.name) == ["森の夜"])
        #expect(choice == themes.first.map { .custom($0.id) })
    }

    @Test
    func restoresDeletedChosenTheme() async throws {
        let setup = try await HomeModelTests.Setup()

        let creating = ThemeEditModel(
            parts: .system(setup.database),
            editing: nil,
            base: ThemePreset.forest.palette
        )

        creating.state.draft.name = "森の夜"
        _ = await creating.save()
        let theme = try #require(try await setup.database.customThemes().first)

        let editing = ThemeEditModel(
            parts: .system(setup.database),
            editing: theme,
            base: ThemePreset.forest.palette
        )

        let deletion = try #require(await editing.delete())
        let afterDelete = try await setup.database.setting(.theme)

        let switcher = AppIconListModelTests.Switcher(name: nil)
        let appIcon = AppIconListModel(switcher: switcher.client)
        let list = ThemeListModel(parts: .system(setup.database), appIcon: appIcon)
        await list.restore(deletion)

        #expect(afterDelete == .preset(.white))
        #expect(list.input.current == .custom(theme.id))
        #expect(list.input.customThemes == [theme])
    }

    @Test
    func keepsTextReadableWhenBackgroundChanges() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeEditModel(
            parts: .system(setup.database),
            editing: nil,
            base: .night
        )

        model.state.choose("#FFFFFF", for: .background)

        #expect(model.state.draft.background == "#FFFFFF")
        #expect(model.output.palette.unreadableRoles.isEmpty)
    }

    @Test
    func disablesUnreadableSwatches() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeEditModel(
            parts: .system(setup.database),
            editing: nil,
            base: .night
        )

        let dark = model.output.isAvailable("#1E1E22", for: .text)
        let light = model.output.isAvailable("#EDE6D6", for: .text)

        #expect(!dark)
        #expect(light)
    }

    @Test
    func blocksUnreadableColors() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeEditModel(
            parts: .system(setup.database),
            editing: nil,
            base: .night
        )

        model.state.draft.name = "読めない"
        model.state.draft.text = model.state.draft.background

        #expect(!model.canSave)
        #expect(model.saveTitle == "文字が読みにくい色です")
    }
}
