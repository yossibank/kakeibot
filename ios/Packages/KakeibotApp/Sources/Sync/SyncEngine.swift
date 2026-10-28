import CloudKit
import Foundation
import Store

public actor SyncEngine {
    private let database: AppDatabase
    private let container: CKContainer
    private var engine: CKSyncEngine?
    private var sending: [SyncKey: SyncChange] = [:]

    public init(
        database: AppDatabase,
        container: CKContainer = CKContainer(identifier: SyncEngine.containerIdentifier)
    ) {
        self.database = database
        self.container = container
    }
}

public extension SyncEngine {
    static let containerIdentifier = "iCloud.com.yossibank.kakeibot"

    func start() async {
        guard engine == nil else {
            return
        }

        let data = try? await database.syncEngineState()
        let state = data.flatMap {
            try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: $0)
        }
        let configuration = CKSyncEngine.Configuration(
            database: container.privateCloudDatabase,
            stateSerialization: state,
            delegate: self
        )
        let engine = CKSyncEngine(configuration)

        self.engine = engine

        if state == nil {
            engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
        }
    }

    func enqueuePending() async {
        await enqueuePending(excluding: [])
    }
}

private extension SyncEngine {
    static var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: "Kakeibot")
    }

    func enqueuePending(excluding failed: Set<SyncKey>) async {
        guard
            engine != nil,
            let changes = try? await database.pendingSyncChanges()
        else {
            return
        }

        enqueue(changes.filter { !failed.contains($0.key) })
    }

    func enqueue(_ changes: [SyncChange]) {
        guard let engine else {
            return
        }

        let pending = Set(engine.state.pendingRecordZoneChanges)
        var added: [CKSyncEngine.PendingRecordZoneChange] = []
        var removed: [CKSyncEngine.PendingRecordZoneChange] = []

        for change in changes {
            let id = change.key.recordID(in: Self.zoneID)
            let save = CKSyncEngine.PendingRecordZoneChange.saveRecord(id)
            let delete = CKSyncEngine.PendingRecordZoneChange.deleteRecord(id)
            let (wanted, opposite) = change.isDeletion ? (delete, save) : (save, delete)

            guard !pending.contains(wanted) else {
                continue
            }

            added.append(wanted)

            if pending.contains(opposite) {
                removed.append(opposite)
            }
        }

        engine.state.remove(pendingRecordZoneChanges: removed)
        engine.state.add(pendingRecordZoneChanges: added)
    }

    func restart() async {
        engine = nil
        sending = [:]
        await start()
    }

    func turnOff() async {
        try? await database.resetSync()
        try? await database.setSyncEnabled(false)

        engine = nil
        sending = [:]
    }

    func record(for recordID: CKRecord.ID) async -> CKRecord? {
        guard
            let key = SyncKey(recordID),
            let local = try? await database.syncRecord(for: key)
        else {
            return nil
        }

        let systemFields = try? await database.syncSystemFields(for: key)
        return try? local.record(in: Self.zoneID, systemFields: systemFields)
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

    func applyFetched(_ changes: CKSyncEngine.Event.FetchedRecordZoneChanges) async {
        let records = changes.modifications.map(\.record)
        let saved = records.compactMap(SyncRecord.init)
        let deleted = changes.deletions.compactMap { SyncKey($0.recordID) }
        let systemFields = records.reduce(into: [SyncKey: Data]()) { fields, record in
            if let key = SyncKey(record.recordID) {
                fields[key] = record.systemFields
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
            .filter { $0.value.code == .unknownItem }
            .map(\.key)
        let deletedIDs = sent.deletedRecordIDs + unknownDeletes
        let deleted = deletedIDs.compactMap(SyncKey.init)
        let systemFields = sent.savedRecords.reduce(into: [SyncKey: Data]()) { fields, record in
            if let key = SyncKey(record.recordID) {
                fields[key] = record.systemFields
            }
        }
        let failedSaves = sent.failedRecordSaves.map(\.record.recordID)
        let failedDeletes = sent.failedRecordDeletes
            .filter { $0.value.code != .unknownItem }
            .map(\.key)
        let failed = Set((failedSaves + failedDeletes).compactMap(SyncKey.init))
        let finished = (Array(systemFields.keys) + deleted)
            .compactMap { sending.removeValue(forKey: $0) }

        try? await database.saveSyncSystemFields(systemFields)
        try? await database.removeSyncSystemFields(deleted)
        try? await database.removeSyncChanges(finished)

        for failure in sent.failedRecordSaves {
            await retry(failure)
        }

        await enqueuePending(excluding: failed)
    }

    func retry(_ failure: CKSyncEngine.Event.SentRecordZoneChanges.FailedRecordSave) async {
        let recordID = failure.record.recordID

        guard let key = SyncKey(recordID) else {
            return
        }

        switch failure.error.code {
        case .serverRecordChanged:
            await resolveConflict(of: key, with: failure.error.serverRecord)
        case .zoneNotFound:
            engine?.state
                .add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
            engine?.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
        case .unknownItem:
            try? await database.removeSyncSystemFields([key])
            engine?.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
        default:
            break
        }
    }

    func resolveConflict(
        of key: SyncKey,
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
                systemFields: [key: serverRecord.systemFields]
            )

            if try await database.syncRecord(for: key) == remote {
                let change = sending.removeValue(forKey: key)
                try await database.removeSyncChanges(change.map { [$0] } ?? [])
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
