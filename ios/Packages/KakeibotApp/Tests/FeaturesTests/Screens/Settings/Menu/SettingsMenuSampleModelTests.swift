#if DEBUG
import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

@MainActor
struct SettingsMenuSampleModelTests {
    @Test
    func tellsWhenSampleIsInserted() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = SettingsMenuModel(parts: .system(setup.database)).sampleModel()
        let start = model.state.progress

        await model.insert(today: setup.date)
        let entries = try await setup.database.entryList().entries

        #expect(start == nil)
        #expect(model.state.progress == .inserted)
        #expect(model.state.progress?.message == "テストデータを入れました")
        #expect(!entries.isEmpty)
    }

    @Test
    func tellsWhenSampleCannotBeInserted() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = SettingsMenuModel(parts: .system(setup.database)).sampleModel()
        try await setup.database.failWrites(to: "entry")

        await model.insert(today: setup.date)

        #expect(model.state.progress == .failed)
        #expect(model.state.progress?.message == "テストデータを入れられませんでした")
    }
}
#endif
