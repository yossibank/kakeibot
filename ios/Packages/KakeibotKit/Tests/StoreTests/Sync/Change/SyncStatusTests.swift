import Foundation
@testable import Store
import Testing

struct SyncStatusTests {
    @Test
    func waitsForFirstFetchWhenTurnedOn() async throws {
        let setup = try await SyncTests.Setup(enabled: false)

        try await setup.database.turnOnSync()
        let turnedOn = try await setup.database.syncStatus()
        try await setup.database.turnOffSync()
        try await setup.database.turnOnSyncReplacingLocal()
        let replaced = try await setup.database.syncStatus()

        #expect(turnedOn.isFetching)
        #expect(replaced.isFetching)
    }

    @Test
    func remembersWhenItLastSynced() async throws {
        let setup = try await SyncTests.Setup()
        let syncedAt = Date(timeIntervalSince1970: 1_793_000_000)

        try await setup.database.setSyncFetching(true)
        let fetching = try await setup.database.syncStatus()
        try await setup.database.setSyncFetching(false)
        try await setup.database.setSyncedAt(syncedAt)
        let synced = try await setup.database.syncStatus()

        #expect(fetching.isFetching)
        #expect(synced.isFetching == false)
        #expect(synced.syncedAt == syncedAt)
    }

    @Test
    func forgetsFetchAndSyncTimeWhenTurnedOff() async throws {
        let setup = try await SyncTests.Setup()
        try await setup.database.setSyncFetching(true)
        try await setup.database.setSyncedAt(Date(timeIntervalSince1970: 1_793_000_000))

        try await setup.database.turnOffSync()
        let status = try await setup.database.syncStatus()

        #expect(status.isFetching == false)
        #expect(status.syncedAt == nil)
    }

    @Test
    func keepsNoFetchOrSyncTimeWhileOff() async throws {
        let setup = try await SyncTests.Setup(enabled: false)

        try await setup.database.setSyncFetching(true)
        try await setup.database.setSyncedAt(Date(timeIntervalSince1970: 1_793_000_000))
        let status = try await setup.database.syncStatus()

        #expect(status.isFetching == false)
        #expect(status.syncedAt == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func tellsWhenFetchingStartsAndEnds() async throws {
        let setup = try await SyncTests.Setup()
        var updates = setup.database.syncStatusUpdates().makeAsyncIterator()

        let first = try await updates.next()
        try await setup.database.setSyncFetching(true)
        let fetching = try await updates.next()
        try await setup.database.setSyncFetching(false)
        let done = try await updates.next()

        #expect(first?.isFetching == false)
        #expect(fetching?.isFetching == true)
        #expect(done?.isFetching == false)
    }
}
