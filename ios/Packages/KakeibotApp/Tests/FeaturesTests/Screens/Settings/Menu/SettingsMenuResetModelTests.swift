import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

@MainActor
struct SettingsMenuResetModelTests {
    @Test
    func asksToConfirmWhenRecordsExist() async throws {
        let setup = try await EntryModelTests.Setup()
        _ = try await setup.saveEntry(amount: 980)
        let model = SettingsMenuResetModel(parts: .system(setup.database))

        let isReady = await model.prepare()

        #expect(isReady)
        #expect(model.state.prompt[.deleteAll])
        #expect(model.input.count == 1)
        #expect(model.state.errorNotice.message == nil)
    }

    @Test
    func tellsInsteadOfConfirmingWhenNothingToDelete() async throws {
        let setup = try await EntryModelTests.Setup()
        let model = SettingsMenuResetModel(parts: .system(setup.database))

        let isReady = await model.prepare()

        #expect(!isReady)
        #expect(!model.state.prompt[.deleteAll])
        #expect(model.state.errorNotice.message == "削除する記録はありません")
    }

    @Test
    func closesConfirmationWhenCountingFails() async throws {
        let setup = try await EntryModelTests.Setup()
        _ = try await setup.saveEntry(amount: 980)
        let model = SettingsMenuResetModel(parts: .system(setup.database))
        await model.prepare()
        try await setup.database.failReads(of: "entry")

        let isReady = await model.prepare()

        #expect(!isReady)
        #expect(!model.state.prompt[.deleteAll])
        #expect(model.state.errorNotice.message == "記録の件数を読めませんでした")
    }

    @Test
    func ignoresPreparingWhileRunning() async throws {
        let setup = try await EntryModelTests.Setup()
        _ = try await setup.saveEntry(amount: 980)
        let model = SettingsMenuResetModel(parts: .system(setup.database))

        let isReady = await model.state.task.attempt {
            await model.prepare()
        }

        #expect(!isReady)
        #expect(!model.state.prompt[.deleteAll])
        #expect(model.input.count == 0)
    }
}
