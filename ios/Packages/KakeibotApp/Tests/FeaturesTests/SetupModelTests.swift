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
    func marksEntryOpenedOnce() async throws {
        let database = try AppDatabase.inMemory()
        let model = SetupModel(database: database)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.isLoaded && !model.isEntryOpened
        }

        await model.markEntryOpened()
        let entryOpened = try await database.setting(.entryOpened)
        try await database.failWrites(to: "setting")
        await model.markEntryOpened()
        task.cancel()

        #expect(entryOpened)
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func clearsUnreadNewsWhenSeen() async throws {
        let database = try AppDatabase.inMemory()
        let model = SetupModel(database: database)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.hasUnreadNews
        }

        await model.markNewsSeen()
        let seen = try await database.setting(.whatsNewSeenVersion)
        task.cancel()

        #expect(seen == WhatsNewRelease.latestVersion)
        #expect(model.hasUnreadNews == false)
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func keepsNewsReadUpToLatestVersion() async throws {
        let database = try AppDatabase.inMemory()
        try await database.setSetting(.whatsNewSeenVersion, to: WhatsNewRelease.latestVersion)
        let model = SetupModel(database: database)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.seenNewsVersion != nil
        }

        task.cancel()

        #expect(model.hasUnreadNews == false)
    }

    @Test
    func keepsNewerSeenVersionFromOtherDevice() async throws {
        let database = try AppDatabase.inMemory()
        try await database.setSetting(.whatsNewSeenVersion, to: "999.0")
        let model = SetupModel(database: database)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.seenNewsVersion != nil
        }

        await model.markNewsSeen()
        let seen = try await database.setting(.whatsNewSeenVersion)
        task.cancel()

        #expect(seen == "999.0")
        #expect(model.hasUnreadNews == false)
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
