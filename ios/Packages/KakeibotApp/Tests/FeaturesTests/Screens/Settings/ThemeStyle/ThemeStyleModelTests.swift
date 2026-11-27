import Core
import FeatureModels
import Features
import Store
import Testing

@MainActor
struct ThemeStyleModelTests {
    @Test
    func savesChosenStyle() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
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

        #expect(model.output.style == expected)
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
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()

        await model.choose(haptics: false)
        await model.choose(haptics: true)

        let style = try await setup.database.style()
        #expect(style.haptics)
    }

    @Test
    func previewChangesStyleWithoutSaving() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()

        model.preview(displayFont: .gothic)
        model.preview(textFont: .rounded)

        let style = try await setup.database.style()

        #expect(model.output.style.displayFont == .gothic)
        #expect(model.output.style.textFont == .rounded)
        #expect(style == .standard)
    }

    @Test
    func cancelPreviewRestoresStyle() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()

        model.preview(displayFont: .gothic)
        model.cancelPreview()

        #expect(model.output.style == .standard)
    }

    @Test
    func cancelPreviewAfterTwoPreviewsRestoresFirstStyle() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()

        model.preview(displayFont: .gothic)
        model.preview(displayFont: .rounded)
        model.cancelPreview()

        #expect(model.output.style == .standard)
    }

    @Test
    func cancelWithoutPreviewKeepsStyle() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()
        await model.choose(haptics: false)

        model.cancelPreview()

        #expect(!model.output.style.haptics)
    }

    @Test
    func chooseAfterPreviewSaves() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()

        model.preview(displayFont: .gothic)
        await model.choose(displayFont: .gothic)

        let style = try await setup.database.style()

        #expect(style.displayFont == .gothic)
        #expect(model.output.style.displayFont == .gothic)

        model.cancelPreview()

        #expect(model.output.style.displayFont == .gothic)
    }

    @Test
    func failedChooseAfterPreviewRestoresStyleBeforePreview() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()
        try await setup.database.failWrites(to: "setting")

        model.preview(displayFont: .gothic)
        await model.choose(displayFont: .rounded)

        #expect(model.output.style == .standard)
        #expect(model.state.notices.error.message == "設定を保存できませんでした")
    }

    @Test
    func offersProForLockedFontWithoutSaving() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()

        await model.choose(.display(.rounded), isPro: false)
        let style = try await setup.database.style()

        #expect(model.state.fontOffer == .display(.rounded))
        #expect(model.state.fontOffer?.feature == "\(ThemeFont.rounded.title)の字体")
        #expect(model.output.style.displayFont == .rounded)
        #expect(style == .standard)
    }

    @Test
    func savesFreeFontAndClosesOffer() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()
        await model.choose(.text(.rounded), isPro: false)

        await model.choose(.text(.gothic), isPro: false)
        let style = try await setup.database.style()

        #expect(model.state.fontOffer == nil)
        #expect(model.state.preview == nil)
        #expect(style.textFont == .gothic)
    }

    @Test
    func savesLockedFontForPro() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()

        await model.choose(.display(.rounded), isPro: true)
        let style = try await setup.database.style()

        #expect(model.state.fontOffer == nil)
        #expect(style.displayFont == .rounded)
    }

    @Test
    func savesOfferedFontAfterUnlock() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()
        await model.choose(.text(.rounded), isPro: false)

        await model.unlockFont()
        let style = try await setup.database.style()

        #expect(model.state.fontOffer == nil)
        #expect(style.textFont == .rounded)
    }

    @Test
    func closingOfferRestoresStyle() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        await model.load()
        await model.choose(.display(.rounded), isPro: false)

        model.closeFontOffer()
        await model.unlockFont()
        let style = try await setup.database.style()

        #expect(model.state.fontOffer == nil)
        #expect(model.output.style == .standard)
        #expect(style == .standard)
    }
}

extension ThemeStyleModelTests {
    @Test
    func keepsStyleOfFirstOpening() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = ThemeStyleModel(parts: .system(setup.database))
        var changed = ThemeStyle.standard

        changed.corner = .small

        let unopened = model.input.openedStyle

        model.open(with: .standard)
        model.open(with: changed)

        #expect(unopened == nil)
        #expect(model.input.openedStyle == .standard)
    }
}
