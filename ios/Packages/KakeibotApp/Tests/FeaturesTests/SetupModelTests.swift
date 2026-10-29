import Core
import Features
import Foundation
import Store
import Testing
import TestSupport

@MainActor
struct SetupModelTests {
    @Test
    func showsCardUntilClosed() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let model = SetupModel(database: database)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.isLoaded
        }

        let shownBefore = model.showsCard
        await model.closeCard()
        let closed = try await database.setting(.setupCardClosed)
        task.cancel()

        #expect(shownBefore)
        #expect(model.cardItems == SetupItem.home)
        #expect(model.showsCard == false)
        #expect(closed)
    }

    @Test
    func marksEntryAndSettingsOpenedOnce() async throws {
        let database = try AppDatabase.inMemory()
        let model = SetupModel(database: database)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.isLoaded && !model.isEntryOpened && !model.isSettingsOpened
        }

        await model.markEntryOpened()
        await model.markSettingsOpened()
        let entryOpened = try await database.setting(.entryOpened)
        let settingsOpened = try await database.setting(.settingsOpened)
        try await database.failWrites(to: "setting")
        await model.markEntryOpened()
        task.cancel()

        #expect(entryOpened)
        #expect(settingsOpened)
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func tellsWhenClosingCardCannotBeSaved() async throws {
        let database = try AppDatabase.inMemory()
        let model = SetupModel(database: database)
        try await database.failWrites(to: "setting")

        await model.closeCard()

        #expect(model.errorNotice.message == "設定を保存できませんでした")
    }
}

private extension SetupModelTests {
    static func wait(
        sourceLocation: SourceLocation = #_sourceLocation,
        until isReady: @escaping @MainActor () -> Bool
    ) async throws {
        await ObservationWait.until(
            sourceLocation: sourceLocation,
            isReady
        )
    }
}
