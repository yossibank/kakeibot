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
        let start = model.state.notices.progress

        await model.insert(today: setup.date)
        let entries = try await setup.database.entryList().entries

        #expect(start == nil)
        #expect(model.state.notices.progress == .inserted)
        #expect(model.state.notices.progress?.message == "テストデータを入れました")
        #expect(!entries.isEmpty)
    }

    @Test
    func tellsWhenSampleCannotBeInserted() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = SettingsMenuModel(parts: .system(setup.database)).sampleModel()
        try await setup.database.failWrites(to: "entry")

        await model.insert(today: setup.date)

        #expect(model.state.notices.progress == .failed)
        #expect(model.state.notices.progress?.message == "テストデータを入れられませんでした")
    }
}
#endif
