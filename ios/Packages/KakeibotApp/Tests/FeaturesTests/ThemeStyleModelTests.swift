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
        await model.choose(ThemeFont.gothic)
        let style = try await setup.database.style()

        #expect(model.style == ThemeStyle(corner: .small, font: .gothic))
        #expect(style == model.style)
    }
}
