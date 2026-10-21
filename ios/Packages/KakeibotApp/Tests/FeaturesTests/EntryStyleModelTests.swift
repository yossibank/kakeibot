import Core
import Features
import Store
import Testing

@MainActor
struct EntryStyleModelTests {
    @Test
    func startsWithDial() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = EntryStyleModel(database: setup.database)

        await model.load()

        #expect(model.style == .dial)
    }

    @Test
    func keepsDialWhenStyleIsNotReady() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = EntryStyleModel(database: setup.database)
        await model.load()

        await model.choose(.card)
        let stored = try await setup.database.setting(.entryStyle)

        #expect(model.style == .dial)
        #expect(stored == .dial)
    }
}
