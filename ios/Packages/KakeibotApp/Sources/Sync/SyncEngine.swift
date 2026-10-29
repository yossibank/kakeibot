import CloudKit
import Foundation
import Store

public actor SyncEngine {
    private let database: AppDatabase
    private let container: CKContainer
    private var engine: CKSyncEngine?
    private var sending: [SyncKey: SyncChange] = [:]
    private var isSyncEnabled = false

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

    static func isAccountAvailable(
        in container: CKContainer = CKContainer(identifier: containerIdentifier)
    ) async -> Bool {
        await (try? container.accountStatus()) == .available
    }

    static func hasCloudData(
        in container: CKContainer = CKContainer(identifier: containerIdentifier)
    ) async throws -> Bool {
        do {
            _ = try await container.privateCloudDatabase.recordZone(for: zoneID)
            return true
        } catch let error as CKError where error.code == .zoneNotFound {
            return false
        }
    }

    static func deleteCloudData(
        in container: CKContainer = CKContainer(identifier: containerIdentifier)
    ) async throws {
        do {
            try await container.privateCloudDatabase.deleteRecordZone(withID: zoneID)
        } catch let error as CKError where error.code == .zoneNotFound {
            return
        }
    }

    func start(isSyncEnabled: Bool) async {
        guard engine == nil else {
            return
        }

        self.isSyncEnabled = isSyncEnabled

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

        if state == nil, isSyncEnabled {
            engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
        }
    }

    func enqueuePending() async {
        await enqueuePending(excluding: [])
    }

    func stop() {
        engine = nil
        sending = [:]
    }
}

private extension SyncEngine {
    static var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: SyncZone.own)
    }

    func enqueuePending(excluding failed: Set<SyncKey>) async {
        guard
            engine != nil,
            let changes = try? await database.pendingSyncChanges()
        else {
            return
        }

        await enqueue(changes.filter { !failed.contains($0.key) })
    }

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
               !saving.contains(change.key) {
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

        if let zone = change.saveZone, isSyncEnabled || zone != SyncZone.own {
            let id = SyncRecordID(key: change.key, zoneName: zone).recordID
            targets.append((.saveRecord(id), .deleteRecord(id)))
        }

        for zone in change.deleteZones where isSyncEnabled || zone != SyncZone.own {
            let id = SyncRecordID(key: change.key, zoneName: zone).recordID
            targets.append((.deleteRecord(id), .saveRecord(id)))
        }

        return targets
    }

    func restart() async {
        let isSyncEnabled = isSyncEnabled

        stop()
        await start(isSyncEnabled: isSyncEnabled)
    }

    func turnOff() async {
        try? await database.turnOffSync()
        stop()
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
            if let walletID = SyncZone.walletID(of: deletion.zoneID.zoneName) {
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
            .filter { $0.value.code == .unknownItem }
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
            .filter { $0.value.code != .unknownItem }
            .map(\.key)
        let failed = Set((failedSaves + failedDeletes).compactMap(SyncKey.init))
        let finished = finishedChanges(saved: Array(systemFields.keys), deleted: deleted)

        try? await database.saveSyncSystemFields(systemFields)
        try? await database.removeSyncSystemFields(deleted)
        try? await database.removeSyncChanges(finished)

        for id in deleted {
            deleteWalletZone(after: id)
        }

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

    func deleteWalletZone(after id: SyncRecordID) {
        guard
            id.key.table == .wallet,
            SyncZone.walletID(of: id.zoneName)?.description == id.key.id
        else {
            return
        }

        let zoneID = CKRecordZone.ID(zoneName: id.zoneName)
        engine?.state.add(pendingDatabaseChanges: [.deleteZone(zoneID)])
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
