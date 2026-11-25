import CloudKit
import Core
import Foundation
import Store

extension SyncEngine {
    func enqueuePending(excluding failed: Set<SyncKey>) async {
        guard
            engine != nil,
            let changes = try? await database.pendingSyncChanges(),
            let owners = try? await database.syncShareOwners()
        else {
            return
        }

        let remaining = changes.filter { !failed.contains($0.key) }

        self.owners = owners

        await enqueue(remaining)
    }

    func record(for recordID: CKRecord.ID) async -> CKRecord? {
        guard let id = SyncRecordID(recordID) else {
            return nil
        }

        do {
            guard
                let local = try await database.syncRecord(for: id),
                try await database.syncSaveZone(for: id.key) == id.zoneName
            else {
                missing.append(recordID)
                return nil
            }

            let systemFields = try? await database.syncSystemFields(for: id)
            return try? local.record(in: recordID.zoneID, systemFields: systemFields)
        } catch {
            return nil
        }
    }

    func dequeueMissing() async {
        guard !missing.isEmpty else {
            return
        }

        let saves = missing.map(CKSyncEngine.PendingRecordZoneChange.saveRecord)

        missing = []
        engine?.state.remove(pendingRecordZoneChanges: saves)

        await enqueuePending()
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
        let finished = finishChanges(saved: savedIDs, deleted: deleted)

        let failureCodes = sent.failedRecordSaves.map(\.error.code)
            + sent.failedRecordDeletes.values.map(\.code)

        let problem = failureCodes.lazy.compactMap(SyncSendProblem.init).first

        try? await database.saveSyncSystemFields(systemFields)
        try? await database.removeSyncSystemFields(deleted)
        try? await database.removeSyncChanges(finished)

        if !isShared,
           problem != nil || !savedIDs.isEmpty || !deleted.isEmpty {
            try? await database.setSyncSendProblem(problem)
        }

        for failure in sent.failedRecordSaves {
            await retry(failure)
        }

        await enqueuePending(excluding: failed)
    }
}

private extension SyncEngine {
    func enqueue(_ changes: [SyncChange]) async {
        guard let engine else {
            return
        }

        let pending = engine.state.pendingRecordZoneChanges.compactMap(SyncRoute.Pending.init)
        let plan = route.enqueue(changes, pending: Set(pending))

        engine.state.remove(pendingRecordZoneChanges: plan.removed.map(pendingChange))
        engine.state.add(pendingRecordZoneChanges: plan.added.map(pendingChange))
        try? await database.removeSyncChanges(plan.dropped)
    }

    func pendingChange(_ pending: SyncRoute.Pending) -> CKSyncEngine.PendingRecordZoneChange {
        switch pending {
        case let .save(id): .saveRecord(recordID(of: id))
        case let .delete(id): .deleteRecord(recordID(of: id))
        }
    }

    func finishChanges(
        saved: [SyncRecordID],
        deleted: [SyncRecordID]
    ) -> [SyncChange] {
        let result = route.finish(
            sending: sending,
            saved: saved,
            deleted: deleted
        )

        let deletions = result.staleDeletions.map { pendingChange(.delete($0)) }

        for change in result.finished {
            sending.removeValue(forKey: change.key)
        }

        engine?.state.add(pendingRecordZoneChanges: deletions)

        return result.finished
    }

    func retry(_ failure: CKSyncEngine.Event.SentRecordZoneChanges.FailedRecordSave) async {
        let recordID = failure.record.recordID

        guard let id = SyncRecordID(recordID) else {
            return
        }

        switch route.retry(after: failure.error.code) {
        case .resolveConflict:
            await resolveConflict(of: id, with: failure.error.serverRecord)

        case .saveZoneAgain:
            guard await (try? database.syncSaveZone(for: id.key)) == id.zoneName else {
                return
            }

            let zone = CKRecordZone(zoneID: recordID.zoneID)

            engine?.state.add(pendingDatabaseChanges: [.saveZone(zone)])
            engine?.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])

        case .sendAgain:
            try? await database.removeSyncSystemFields([id])
            engine?.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])

        case .skip:
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
                systemFields: [id: serverRecord.systemFields],
                at: Date()
            )

            if try await database.syncRecord(for: id) == remote {
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
