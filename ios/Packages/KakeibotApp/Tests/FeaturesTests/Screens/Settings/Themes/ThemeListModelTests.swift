import Core
import FeatureModels
import Features
import Foundation
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
        let suggested = model.state.presented.suggestedIcon
        await model.use(suggested)

        #expect(suggested == .sage)
        #expect(model.state.presented.suggestedIcon == nil)
        #expect(switcher.name == "AppIcon-Sage")
    }

    @Test
    func skipsSuggestionForSameIcon() async throws {
        let setup = try await HomeModelTests.Setup()
        let switcher = AppIconListModelTests.Switcher(name: "AppIcon-Wine")
        let appIcon = AppIconListModel(switcher: switcher.client)
        let model = ThemeListModel(parts: .system(setup.database), appIcon: appIcon)

        await model.select(.preset(.wine))

        #expect(model.state.presented.suggestedIcon == nil)
    }
}

private extension ThemeListModelTests {
    static let draft = ThemeDraft(name: "わたしの色", palette: ThemePreset.wine.palette)

    static func model(database: AppDatabase) -> ThemeListModel {
        let switcher = AppIconListModelTests.Switcher(name: nil)
        let appIcon = AppIconListModel(switcher: switcher.client)
        return ThemeListModel(parts: .system(database), appIcon: appIcon)
    }
}

extension ThemeListModelTests {
    @Test
    func offersProBeforeChoosingCustomTheme() async throws {
        let setup = try await HomeModelTests.Setup()
        let saved = try await setup.database.saveTheme(Self.draft, at: Date())
        let model = Self.model(database: setup.database)
        await model.load()

        await model.choose(.custom(saved.id), isPro: false)
        let offered = model.state.presented.overlay.current
        let kept = model.input.current

        await model.unlock()

        #expect(offered == .offer(.select(.custom(saved.id))))
        #expect(offered?.offer?.feature == "作ったテーマ")
        #expect(kept == .system)
        #expect(model.state.presented.overlay.current == nil)
        #expect(model.input.current == .custom(saved.id))
    }

    @Test
    func opensNewThemeAfterUnlocking() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = Self.model(database: setup.database)
        let base = ThemePreset.wine.palette

        model.create(base: base, isPro: false)
        let offered = model.state.presented.overlay.current

        await model.unlock()
        let unlocked = model.state.presented.overlay.current

        model.create(base: nil, isPro: true)

        #expect(offered == .offer(.create(base: base)))
        #expect(unlocked == .editing(.new(base: base)))
        #expect(model.state.presented.overlay.current?.editing == .new(base: nil))
    }

    @Test
    func presentsOneThingAtATime() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = Self.model(database: setup.database)
        let choice = ThemeChoice.preset(.forest)

        model.state.press(choice)
        let pressed = model.state.presented.pressing
        model.state.press(nil)
        model.state.present(.menu(choice))
        let menu = model.state.presented.overlay.current?.menu

        model.state.present(.editing(.new(base: nil)))
        model.state.close(.menu(choice))
        let kept = model.state.presented.overlay.current

        model.state.close(kept)

        #expect(pressed == choice)
        #expect(model.state.presented.pressing == nil)
        #expect(menu == choice)
        #expect(kept == .editing(.new(base: nil)))
        #expect(model.state.presented.overlay.current == nil)
    }

    @Test
    func findsPaletteAndThemeOfChoice() async throws {
        let setup = try await HomeModelTests.Setup()
        let saved = try await setup.database.saveTheme(Self.draft, at: Date())
        let model = Self.model(database: setup.database)
        await model.load()

        #expect(model.output.theme(of: .custom(saved.id))?.id == saved.id)
        #expect(model.output.palette(of: .custom(saved.id)) == saved.palette)
        #expect(model.output.theme(of: .preset(.wine)) == nil)
        #expect(model.output.palette(of: .preset(.wine)) == ThemePreset.wine.palette)
        #expect(model.output.palette(of: .system) == ThemePreset.white.palette)
    }
}
