import Core
import Foundation
@testable import Store
@testable import Sync
import Testing

struct SyncSendOrderTests {
    @Test
    func sendsNothingToKeepForEntryDeletedBeforeItIsQueued() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()

        try await device.database.deleteEntry(entry.id, at: Device.now)
        try await device.sync()

        #expect(device.cloud[entry.ownRecordID] == nil)
        #expect(try await device.waitingKeys.isEmpty)
        #expect(device.pending.isEmpty)
    }

    @Test
    func finishesDeletionOfEntryWhoseSaveWasQueuedButNeverSent() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.enqueue()

        try await device.database.deleteEntry(entry.id, at: Device.now)
        try await device.sync()

        #expect(device.cloud[entry.ownRecordID] == nil)
        #expect(try await device.waitingKeys.isEmpty)
        #expect(device.pending.isEmpty)
    }

    @Test
    func finishesDeletionWhenBatchIsBuiltBeforeDeletionIsQueued() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.enqueue()

        try await device.database.deleteEntry(entry.id, at: Device.now)
        let batch = try await device.takeBatch()
        let queued = device.pending
        try await device.sync()

        #expect(batch == nil)
        #expect(queued == [.delete(entry.ownRecordID)])
        #expect(device.cloud[entry.ownRecordID] == nil)
        #expect(try await device.waitingKeys.isEmpty)
        #expect(device.pending.isEmpty)
    }

    @Test
    func finishesDeletionOfEntryEditedWhileItsSaveWasQueued() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry(amount: 500)
        try await device.enqueue()
        _ = try await device.saveEntry(amount: 800, editing: entry.id)
        try await device.enqueue()

        try await device.database.deleteEntry(entry.id, at: Device.now)
        try await device.sync()

        #expect(device.cloud[entry.ownRecordID] == nil)
        #expect(try await device.waitingKeys.isEmpty)
        #expect(device.pending.isEmpty)
    }

    @Test(arguments: [true, false])
    func finishesDeletionOfQueuedEntryAfterAppReopens(keepingEngineState: Bool) async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.enqueue()
        try await device.database.deleteEntry(entry.id, at: Device.now)

        try await device.relaunch(keepingEngineState: keepingEngineState)
        try await device.fetch()
        try await device.sync()

        #expect(device.cloud[entry.ownRecordID] == nil)
        #expect(try await device.database.entry(entry.id) == nil)
        #expect(try await device.waitingKeys.isEmpty)
        #expect(device.pending.isEmpty)
    }

    @Test
    func sendsEntryDeletedAndRestoredWhileItsSaveWasQueued() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.enqueue()

        try await device.database.deleteEntry(entry.id, at: Device.now)
        try await device.enqueue()
        try await device.database.restoreEntry(entry, at: Device.now)
        try await device.sync()

        let local = try await device.database.syncRecord(for: entry.syncKey)

        #expect(local != nil)
        #expect(device.cloud[entry.ownRecordID] == local)
        #expect(try await device.waitingKeys.isEmpty)
        #expect(device.pending.isEmpty)
    }

    @Test
    func sendsOnlyNewEntryWhenQueuedEntryIsDeletedAndRecordedAgain() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry(amount: 500)
        try await device.enqueue()

        try await device.database.deleteEntry(entry.id, at: Device.now)
        let again = try await device.saveEntry(amount: 800)
        try await device.sync()

        #expect(device.cloud[entry.ownRecordID] == nil)
        #expect(device.cloud[again.ownRecordID]?.values["amount"] == .integer(800))
        #expect(try await device.waitingKeys.isEmpty)
        #expect(device.pending.isEmpty)
    }

    @Test
    func deletesFromCloudEntryDeletedWhileItsSaveIsInFlight() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.enqueue()
        let batch = try #require(try await device.takeBatch())

        try await device.database.deleteEntry(entry.id, at: Device.now)
        try await device.enqueue()
        try await device.deliver(batch)
        let arrived = device.cloud[entry.ownRecordID]
        try await device.sync()

        #expect(arrived != nil)
        #expect(device.cloud[entry.ownRecordID] == nil)
        #expect(try await device.waitingKeys.isEmpty)
        #expect(try await device.database.syncSystemFields(for: entry.ownRecordID) == nil)
    }

    @Test(arguments: [true, false])
    func deletesFromCloudEntryDeletedBeforeAppClosesWithSaveInFlight(
        keepingEngineState: Bool
    ) async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.enqueue()
        let batch = try #require(try await device.takeBatch())
        try await device.database.deleteEntry(entry.id, at: Device.now)
        device.arrive(batch)

        try await device.relaunch(keepingEngineState: keepingEngineState)
        try await device.fetch()
        try await device.sync()

        #expect(device.cloud[entry.ownRecordID] == nil)
        #expect(try await device.database.entry(entry.id) == nil)
        #expect(try await device.waitingKeys.isEmpty)
    }

    @Test
    func deletesFromCloudEntryDeletedAfterAppReopensWithSaveUnconfirmed() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.enqueue()
        let batch = try #require(try await device.takeBatch())
        device.arrive(batch)

        try await device.relaunch(keepingEngineState: false)
        try await device.database.deleteEntry(entry.id, at: Device.now)
        try await device.fetch()
        try await device.sync()

        #expect(device.cloud[entry.ownRecordID] == nil)
        #expect(try await device.database.entry(entry.id) == nil)
        #expect(try await device.waitingKeys.isEmpty)
    }

    @Test
    func finishesDeletionWhenSaveInFlightNeverReachedCloud() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.enqueue()
        _ = try #require(try await device.takeBatch())

        try await device.database.deleteEntry(entry.id, at: Device.now)
        try await device.relaunch(keepingEngineState: false)
        try await device.sync()

        #expect(device.cloud[entry.ownRecordID] == nil)
        #expect(try await device.waitingKeys.isEmpty)
        #expect(try await device.database.syncSystemFields(for: entry.ownRecordID) == nil)
    }

    @Test
    func sendsAgainEntryRestoredWhileItsDeletionIsInFlight() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.sync()
        try await device.database.deleteEntry(entry.id, at: Device.now)
        try await device.enqueue()
        let batch = try #require(try await device.takeBatch())

        try await device.database.restoreEntry(entry, at: Device.now)
        try await device.enqueue()
        try await device.deliver(batch)
        let afterDeletion = device.cloud[entry.ownRecordID]
        try await device.sync()

        let local = try await device.database.syncRecord(for: entry.syncKey)

        #expect(afterDeletion == nil)
        #expect(local != nil)
        #expect(device.cloud[entry.ownRecordID] == local)
        #expect(try await device.waitingKeys.isEmpty)
    }

    @Test
    func keepsEntryDeletedAndRestoredBeforeItsDeletionIsSent() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.sync()

        try await device.database.deleteEntry(entry.id, at: Device.now)
        try await device.enqueue()
        try await device.database.restoreEntry(entry, at: Device.now)
        try await device.sync()

        let local = try await device.database.syncRecord(for: entry.syncKey)

        #expect(local != nil)
        #expect(device.cloud[entry.ownRecordID] == local)
        #expect(try await device.waitingKeys.isEmpty)
        #expect(device.pending.isEmpty)
    }

    @Test
    func keepsEntryDeletedAndRestoredWhileItsSaveIsInFlight() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.enqueue()
        let batch = try #require(try await device.takeBatch())

        try await device.database.deleteEntry(entry.id, at: Device.now)
        try await device.enqueue()
        try await device.database.restoreEntry(entry, at: Device.now)
        try await device.enqueue()
        try await device.deliver(batch)
        try await device.sync()

        let local = try await device.database.syncRecord(for: entry.syncKey)

        #expect(local != nil)
        #expect(device.cloud[entry.ownRecordID] == local)
        #expect(try await device.waitingKeys.isEmpty)
        #expect(device.pending.isEmpty)
    }

    @Test
    func sendsAgainNoSpendDayMarkedAgainWhileItsDeletionIsInFlight() async throws {
        let device = try await Device.syncing()
        let key = SyncKey(table: .noSpendDay, id: Device.date.description)
        let id = SyncRecordID(key: key, zoneName: SyncZone.own)
        try await device.database.markNoSpendDay(Device.date, at: Device.now)
        try await device.sync()
        try await device.database.unmarkNoSpendDay(Device.date)
        try await device.enqueue()
        let batch = try #require(try await device.takeBatch())

        try await device.database.markNoSpendDay(Device.date, at: Device.now)
        try await device.deliver(batch)
        let afterDeletion = device.cloud[id]
        try await device.sync()

        let local = try await device.database.syncRecord(for: key)

        #expect(afterDeletion == nil)
        #expect(local != nil)
        #expect(device.cloud[id] == local)
        #expect(try await device.waitingKeys.isEmpty)
    }

    @Test
    func sendsAgainEntryEditedWhileItsSaveIsInFlight() async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry(amount: 500)
        try await device.enqueue()
        let batch = try #require(try await device.takeBatch())

        _ = try await device.saveEntry(amount: 800, editing: entry.id)
        try await device.deliver(batch)
        let first = device.cloud[entry.ownRecordID]
        try await device.sync()

        #expect(first?.values["amount"] == .integer(500))
        #expect(device.cloud[entry.ownRecordID]?.values["amount"] == .integer(800))
        #expect(try await device.waitingKeys.isEmpty)
    }

    @Test(arguments: [true, false])
    func sendsEntryQueuedBeforeAppClosed(keepingEngineState: Bool) async throws {
        let device = try await Device.syncing()
        let entry = try await device.saveEntry()
        try await device.enqueue()

        try await device.relaunch(keepingEngineState: keepingEngineState)
        try await device.fetch()
        try await device.sync()

        let local = try await device.database.syncRecord(for: entry.syncKey)

        #expect(local != nil)
        #expect(device.cloud[entry.ownRecordID] == local)
        #expect(try await device.waitingKeys.isEmpty)
    }
}
