import CloudKit
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

        self.owners = owners
        await enqueue(changes.filter { !failed.contains($0.key) })
    }

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
        let failedSaves = sent.failedRecordSaves.map(\.record.recordID)
        let failedDeletes = sent.failedRecordDeletes
            .filter { !Self.goneCodes.contains($0.value.code) }
            .map(\.key)
        let failed = Set((failedSaves + failedDeletes).compactMap(SyncKey.init))
        let finished = finishedChanges(saved: Array(systemFields.keys), deleted: deleted)

        try? await database.saveSyncSystemFields(systemFields)
        try? await database.removeSyncSystemFields(deleted)
        try? await database.removeSyncChanges(finished)

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

        let pending = Set(engine.state.pendingRecordZoneChanges)

        let saving = Set(pending.compactMap { change -> SyncKey? in
            guard case let .saveRecord(id) = change else {
                return nil
            }

            return SyncKey(id)
        })

        var added: [CKSyncEngine.PendingRecordZoneChange] = []
        var removed: [CKSyncEngine.PendingRecordZoneChange] = []
        var dropped: [SyncChange] = []

        for change in changes {
            let targets = pendingTargets(of: change)

            if targets.isEmpty,
               !isShared,
               !saving.contains(change.key),
               !change.zones.contains(where: isForeign) {
                dropped.append(change)
            }

            for (wanted, opposite) in targets where !pending.contains(wanted) {
                added.append(wanted)

                if pending.contains(opposite) {
                    removed.append(opposite)
                }
            }
        }

        engine.state.remove(pendingRecordZoneChanges: removed)
        engine.state.add(pendingRecordZoneChanges: added)
        try? await database.removeSyncChanges(dropped)
    }

    func pendingTargets(
        of change: SyncChange
    ) -> [(
        wanted: CKSyncEngine.PendingRecordZoneChange,
        opposite: CKSyncEngine.PendingRecordZoneChange
    )] {
        var targets: [(
            wanted: CKSyncEngine.PendingRecordZoneChange,
            opposite: CKSyncEngine.PendingRecordZoneChange
        )] = []

        if let zone = change.saveZone, sends(to: zone) {
            let id = recordID(of: SyncRecordID(key: change.key, zoneName: zone))
            targets.append((.saveRecord(id), .deleteRecord(id)))
        }

        for zone in change.deleteZones where sends(to: zone) {
            let id = recordID(of: SyncRecordID(key: change.key, zoneName: zone))
            targets.append((.deleteRecord(id), .saveRecord(id)))
        }

        return targets
    }

    func finishedChanges(
        saved: [SyncRecordID],
        deleted: [SyncRecordID]
    ) -> [SyncChange] {
        var finished: [SyncChange] = []

        for id in saved {
            guard let change = sending[id.key], change.saveZone == id.zoneName else {
                continue
            }

            sending.removeValue(forKey: id.key)
            finished.append(change)
            engine?.state.add(pendingRecordZoneChanges: staleDeletions(of: change))
        }

        let zones = Dictionary(grouping: deleted, by: \.key).mapValues { Set($0.map(\.zoneName)) }

        for (key, deletedZones) in zones {
            guard
                let change = sending[key],
                change.saveZone == nil,
                Set(change.deleteZones.filter { sends(to: $0) }).isSubset(of: deletedZones)
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
            .filter { sends(to: $0) }
            .map { .deleteRecord(recordID(of: SyncRecordID(key: change.key, zoneName: $0))) }
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
            guard
                !isShared,
                await (try? database.syncSaveZone(for: id.key)) == id.zoneName
            else {
                return
            }

            engine?.state
                .add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: recordID.zoneID))])
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
                try await database.removeSyncChanges(change.map { [$0] } ?? [])
            } else {
                engine?.state.add(pendingRecordZoneChanges: [.saveRecord(serverRecord.recordID)])
            }
        } catch {
            return
        }
    }
}
