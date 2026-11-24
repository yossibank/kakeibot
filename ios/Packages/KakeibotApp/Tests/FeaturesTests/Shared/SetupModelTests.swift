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
        let model = SetupModel(database: database, newsVersion: WhatsNewRelease.latestVersion)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.output.isLoaded
        }

        let shownBefore = model.output.showsCard
        await model.closeCard()
        let closed = try await database.setting(.setupCardClosed)
        task.cancel()

        #expect(shownBefore)
        #expect(model.output.cardItems == SetupItem.home)
        #expect(model.output.showsCard == false)
        #expect(closed)
    }

    @Test
    func marksEntryOpenedOnce() async throws {
        let database = try AppDatabase.inMemory()
        let model = SetupModel(database: database, newsVersion: WhatsNewRelease.latestVersion)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.output.isLoaded && !model.input.isEntryOpened
        }

        await model.markEntryOpened()
        let entryOpened = try await database.setting(.entryOpened)
        try await database.failWrites(to: "setting")
        await model.markEntryOpened()
        task.cancel()

        #expect(entryOpened)
        #expect(model.state.errorNotice.message == nil)
    }

    @Test
    func clearsUnreadNewsWhenSeen() async throws {
        let database = try AppDatabase.inMemory()
        let model = SetupModel(database: database, newsVersion: WhatsNewRelease.latestVersion)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.output.hasUnreadNews
        }

        await model.markNewsSeen()
        let seen = try await database.setting(.whatsNewSeenVersion)
        task.cancel()

        #expect(seen == WhatsNewRelease.latestVersion)
        #expect(model.output.hasUnreadNews == false)
        #expect(model.state.errorNotice.message == nil)
    }

    @Test
    func keepsNewsReadUpToLatestVersion() async throws {
        let database = try AppDatabase.inMemory()
        try await database.setSetting(.whatsNewSeenVersion, to: WhatsNewRelease.latestVersion)
        let model = SetupModel(database: database, newsVersion: WhatsNewRelease.latestVersion)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.output.seenNewsVersion != nil
        }

        task.cancel()

        #expect(model.output.hasUnreadNews == false)
    }

    @Test
    func keepsNewerSeenVersionFromOtherDevice() async throws {
        let database = try AppDatabase.inMemory()
        try await database.setSetting(.whatsNewSeenVersion, to: "999.0")
        let model = SetupModel(database: database, newsVersion: WhatsNewRelease.latestVersion)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.output.seenNewsVersion != nil
        }

        await model.markNewsSeen()
        let seen = try await database.setting(.whatsNewSeenVersion)
        task.cancel()

        #expect(seen == "999.0")
        #expect(model.output.hasUnreadNews == false)
    }

    @Test
    func tellsWhenClosingCardCannotBeSaved() async throws {
        let database = try AppDatabase.inMemory()
        let model = SetupModel(database: database, newsVersion: WhatsNewRelease.latestVersion)
        try await database.failWrites(to: "setting")

        await model.closeCard()

        #expect(model.state.errorNotice.message == "設定を保存できませんでした")
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
