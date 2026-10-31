import Core
import Features
import Store
import Testing

@MainActor
struct ThemeStyleModelTests {
    @Test
    func savesChosenStyle() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(database: setup.database)
        await model.load()

        await model.choose(ThemeCorner.small)
        await model.choose(displayFont: .gothic)
        await model.choose(textFont: .rounded)
        await model.choose(ThemeTextSize.large)
        await model.choose(ThemeRowSpacing.relaxed)
        await model.choose(ThemeStampShape.seal)
        await model.choose(showsTabTitles: false)
        await model.choose(ThemeBackdrop.ruled)
        await model.choose(haptics: false)
        await model.choose(decorations: false)

        let style = try await setup.database.style()

        let expected = ThemeStyle(
            corner: .small,
            displayFont: .gothic,
            textFont: .rounded,
            textSize: .large,
            rowSpacing: .relaxed,
            stampShape: .seal,
            showsTabTitles: false,
            backdrop: .ruled,
            haptics: false,
            decorations: false
        )

        #expect(model.style == expected)
        #expect(style == expected)
    }

    @Test
    func readsStandardStyleWhenNothingIsSaved() async throws {
        let setup = try await HomeModelTests.Setup()
        let style = try await setup.database.style()
        #expect(style == .standard)
    }

    @Test
    func turnsSwitchBackOn() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(database: setup.database)
        await model.load()

        await model.choose(haptics: false)
        await model.choose(haptics: true)

        let style = try await setup.database.style()
        #expect(style.haptics)
    }

    @Test
    func previewChangesStyleWithoutSaving() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(database: setup.database)
        await model.load()

        model.preview(displayFont: .gothic)
        model.preview(textFont: .rounded)

        let style = try await setup.database.style()

        #expect(model.style.displayFont == .gothic)
        #expect(model.style.textFont == .rounded)
        #expect(style == .standard)
    }

    @Test
    func cancelPreviewRestoresStyle() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(database: setup.database)
        await model.load()

        model.preview(displayFont: .gothic)
        model.cancelPreview()

        #expect(model.style == .standard)
    }

    @Test
    func cancelPreviewAfterTwoPreviewsRestoresFirstStyle() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(database: setup.database)
        await model.load()

        model.preview(displayFont: .gothic)
        model.preview(displayFont: .rounded)
        model.cancelPreview()

        #expect(model.style == .standard)
    }

    @Test
    func cancelWithoutPreviewKeepsStyle() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(database: setup.database)
        await model.load()
        await model.choose(haptics: false)

        model.cancelPreview()

        #expect(!model.style.haptics)
    }

    @Test
    func chooseAfterPreviewSaves() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(database: setup.database)
        await model.load()

        model.preview(displayFont: .gothic)
        await model.choose(displayFont: .gothic)

        let style = try await setup.database.style()

        #expect(style.displayFont == .gothic)
        #expect(model.style.displayFont == .gothic)

        model.cancelPreview()

        #expect(model.style.displayFont == .gothic)
    }

    @Test
    func failedChooseAfterPreviewRestoresStyleBeforePreview() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(database: setup.database)
        await model.load()
        try await setup.database.failWrites(to: "setting")

        model.preview(displayFont: .gothic)
        await model.choose(displayFont: .rounded)

        #expect(model.style == .standard)
        #expect(model.errorNotice.message == "設定を保存できませんでした")
    }
}
