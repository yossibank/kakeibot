import CloudKit
import Foundation
import Store

private extension SyncEngine {
    static let goneCodes: Set<CKError.Code> = [.unknownItem, .zoneNotFound]

    func record(for recordID: CKRecord.ID) async -> CKRecord? {
        guard
            let id = SyncRecordID(recordID),
            let local = try? await database.syncRecord(for: id.key),
            let zone = try? await database.syncSaveZone(for: id.key),
            zone == id.zoneName
        else {
            return nil
        }

        let systemFields = try? await database.syncSystemFields(for: id)
        return try? local.record(in: recordID.zoneID, systemFields: systemFields)
    }

    func changeAccount(_ change: CKSyncEngine.Event.AccountChange) async {
        switch change.changeType {
        case .signIn:
            try? await database.queueAllForSync()
        case .signOut, .switchAccounts:
            await turnOff()
        @unknown default:
            break
        }
    }

    func deleteZone(_ deletion: CKDatabase.DatabaseChange.Deletion) async {
        guard deletion.zoneID == Self.zoneID else {
            if let walletID = SyncZone.walletID(of: deletion.zoneID.zoneName),
               await isGone(deletion.zoneID) {
                try? await database.endSharing(walletID)
            }

            return
        }

        switch deletion.reason {
        case .encryptedDataReset:
            try? await database.resetSync()
            await restart()
            try? await database.queueAllForSync()
        default:
            await turnOff()
        }
    }

    func isGone(_ zoneID: CKRecordZone.ID) async -> Bool {
        do {
            _ = try await container.privateCloudDatabase.recordZone(for: zoneID)
            return false
        } catch let error as CKError where error.code == .zoneNotFound {
            return true
        } catch {
            return false
        }
    }

    func isSent(to zoneName: String) -> Bool {
        isSyncEnabled || zoneName != SyncZone.own
    }

    func applyFetched(_ changes: CKSyncEngine.Event.FetchedRecordZoneChanges) async {
        let records = changes.modifications
            .map(\.record)
            .filter { isSent(to: $0.recordID.zoneID.zoneName) }

        let saved = records.compactMap(SyncRecord.init)

        let deleted = changes.deletions
            .compactMap { SyncRecordID($0.recordID) }
            .filter { isSent(to: $0.zoneName) }

        let systemFields = records.reduce(into: [SyncRecordID: Data]()) { fields, record in
            if let id = SyncRecordID(record.recordID) {
                fields[id] = record.systemFields
            }
        }

        do {
            try await database.applySyncChanges(
                saved: saved,
                deleted: deleted,
                systemFields: systemFields
            )
        } catch {
            try? await database.resetSync()
            await restart()
        }
    }

    func finishSending(_ sent: CKSyncEngine.Event.SentRecordZoneChanges) async {
        let unknownDeletes = sent.failedRecordDeletes
            .filter { Self.goneCodes.contains($0.value.code) }
            .map(\.key)

        let deletedIDs = sent.deletedRecordIDs + unknownDeletes
        let deleted = deletedIDs.compactMap(SyncRecordID.init)

        let systemFields = sent.savedRecords
            .reduce(into: [SyncRecordID: Data]()) { fields, record in
                if let id = SyncRecordID(record.recordID) {
                    fields[id] = record.systemFields
                }
            }

        let savedIDs = Array(systemFields.keys)
        let failedSaves = sent.failedRecordSaves.map(\.record.recordID)

        let failedDeletes = sent.failedRecordDeletes
            .filter { !Self.goneCodes.contains($0.value.code) }
            .map(\.key)

        let failedKeys = (failedSaves + failedDeletes).compactMap(SyncKey.init)
        let failed = Set(failedKeys)
        let finished = finishedChanges(saved: savedIDs, deleted: deleted)

        try? await database.saveSyncSystemFields(systemFields)
        try? await database.removeSyncSystemFields(deleted)
        try? await database.removeSyncChanges(finished)

        for failure in sent.failedRecordSaves {
            await retry(failure)
        }

        await enqueuePending(excluding: failed)
    }

    func finishedChanges(
        saved: [SyncRecordID],
        deleted: [SyncRecordID]
    ) -> [SyncChange] {
        var finished: [SyncChange] = []

        for id in saved {
            guard
                let change = sending[id.key],
                change.saveZone == id.zoneName
            else {
                continue
            }

            let deletions = staleDeletions(of: change)

            sending.removeValue(forKey: id.key)
            finished.append(change)
            engine?.state.add(pendingRecordZoneChanges: deletions)
        }

        let zones = Dictionary(grouping: deleted, by: \.key).mapValues { Set($0.map(\.zoneName)) }

        for (key, deletedZones) in zones {
            guard
                let change = sending[key],
                change.saveZone == nil,
                Set(change.deleteZones.filter { isSent(to: $0) }).isSubset(of: deletedZones)
            else {
                continue
            }

            sending.removeValue(forKey: key)
            finished.append(change)
        }

        return finished
    }

    func staleDeletions(of change: SyncChange) -> [CKSyncEngine.PendingRecordZoneChange] {
        change.deleteZones
            .filter { isSent(to: $0) }
            .map { .deleteRecord(SyncRecordID(key: change.key, zoneName: $0).recordID) }
    }

    func retry(_ failure: CKSyncEngine.Event.SentRecordZoneChanges.FailedRecordSave) async {
        let recordID = failure.record.recordID

        guard let id = SyncRecordID(recordID) else {
            return
        }

        switch failure.error.code {
        case .serverRecordChanged:
            await resolveConflict(of: id, with: failure.error.serverRecord)
        case .zoneNotFound:
            guard await (try? database.syncSaveZone(for: id.key)) == id.zoneName else {
                return
            }

            let zone = CKRecordZone(zoneID: recordID.zoneID)

            engine?.state.add(pendingDatabaseChanges: [.saveZone(zone)])
            engine?.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
        case .unknownItem:
            try? await database.removeSyncSystemFields([id])
            engine?.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
        default:
            break
        }
    }

    func resolveConflict(
        of id: SyncRecordID,
        with serverRecord: CKRecord?
    ) async {
        guard
            let serverRecord,
            let remote = SyncRecord(serverRecord)
        else {
            return
        }

        do {
            try await database.applySyncChanges(
                saved: [remote],
                deleted: [],
                systemFields: [id: serverRecord.systemFields]
            )

            if try await database.syncRecord(for: id.key) == remote {
                let change = sending.removeValue(forKey: id.key)
                let changes = change.map { [$0] } ?? []
                try await database.removeSyncChanges(changes)
            } else {
                engine?.state.add(pendingRecordZoneChanges: [.saveRecord(serverRecord.recordID)])
            }
        } catch {
            return
        }
    }
}

extension SyncEngine: CKSyncEngineDelegate {
    public func handleEvent(
        _ event: CKSyncEngine.Event,
        syncEngine: CKSyncEngine
    ) async {
        guard syncEngine === engine else {
            return
        }

        switch event {
        case let .stateUpdate(update):
            let data = try? JSONEncoder().encode(update.stateSerialization)
            try? await database.saveSyncEngineState(data)
        case let .accountChange(change):
            await changeAccount(change)
        case let .fetchedDatabaseChanges(changes):
            for deletion in changes.deletions {
                await deleteZone(deletion)
            }
        case let .fetchedRecordZoneChanges(changes):
            await applyFetched(changes)
        case let .sentRecordZoneChanges(sent):
            await finishSending(sent)
        default:
            break
        }
    }

    public func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let changes = syncEngine.state.pendingRecordZoneChanges
            .filter { context.options.scope.contains($0) }

        let local = await (try? database.pendingSyncChanges()) ?? []

        for change in local {
            sending[change.key] = change
        }

        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: changes) { recordID in
            await self.record(for: recordID)
        }
    }
}
