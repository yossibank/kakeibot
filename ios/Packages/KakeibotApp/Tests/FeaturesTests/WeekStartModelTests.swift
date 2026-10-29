import Core
import Features
import Store
import Testing

@MainActor
struct WeekStartModelTests {
    @Test
    func savesChosenDay() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = WeekStartModel(database: setup.database)
        await model.load()

        await model.choose(.monday)
        let saved = try await setup.database.setting(.weekStart)

        #expect(model.weekStart == .monday)
        #expect(saved == .monday)
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func rollsBackAndTellsWhenSavingFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = WeekStartModel(database: setup.database)
        await model.load()
        try await setup.database.failWrites(to: "setting")

        await model.choose(.monday)
        let saved = try await setup.database.setting(.weekStart)

        #expect(model.weekStart == .sunday)
        #expect(saved == .sunday)
        #expect(model.errorNotice.message == "設定を保存できませんでした")
    }
}
