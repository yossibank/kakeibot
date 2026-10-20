import Core
import Features
import Store
import Testing

@MainActor
struct LaunchScreenModelTests {
    @Test
    func savesChosenScreen() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = LaunchScreenModel(database: setup.database)
        await model.load()

        await model.choose(.review)
        let screen = try await setup.database.setting(.launchScreen)

        #expect(model.screen == .review)
        #expect(screen == .review)
    }
}
