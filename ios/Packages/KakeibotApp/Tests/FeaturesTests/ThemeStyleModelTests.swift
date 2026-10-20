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
        let style = try await setup.database.style()
        let expected = ThemeStyle(
            corner: .small,
            displayFont: .gothic,
            textFont: .rounded
        )

        #expect(model.style == expected)
        #expect(style == expected)
    }
}
