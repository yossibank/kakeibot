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
        await model.choose(ThemeBackdrop.washi)
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
            backdrop: .washi,
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
}
