import Core
import FeatureModels
import Features
import Testing

extension EntryModelTests {
    @Test
    func tellsWhenLoadingFails() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        try await setup.database.failReads(of: "setting")

        await model.load()

        #expect(model.state.errorNotice.message == "保存できませんでした")
    }

    @Test
    func tellsWhenDeletingFails() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(
            parts: .system(setup.database),
            editing: entry.id,
            date: setup.date
        )
        await model.load()
        try await setup.database.failWrites(to: "entry")

        let deleted = await model.delete()
        let stored = try await setup.database.entry(entry.id)

        #expect(deleted == nil)
        #expect(stored == entry)
        #expect(model.state.errorNotice.message == "保存できませんでした")
    }
}
