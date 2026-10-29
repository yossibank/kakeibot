import CloudKit
import Foundation
import Store

public actor SyncEngine {
    var sending: [SyncKey: SyncChange] = [:]

    let database: AppDatabase
    let container: CKContainer

    private(set) var engine: CKSyncEngine?
    private(set) var isSyncEnabled = false

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

        if state == nil,
           isSyncEnabled {
            let zone = CKRecordZone(zoneID: Self.zoneID)
            engine.state.add(pendingDatabaseChanges: [.saveZone(zone)])
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

extension SyncEngine {
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

        let remaining = changes.filter { !failed.contains($0.key) }

        await enqueue(remaining)
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
}

private extension SyncEngine {
    func enqueue(_ changes: [SyncChange]) async {
        guard let engine else {
            return
        }

        let pending = Set(engine.state.pendingRecordZoneChanges)

        let savingKeys = pending.compactMap { change -> SyncKey? in
            guard case let .saveRecord(id) = change else {
                return nil
            }

            return SyncKey(id)
        }

        let saving = Set(savingKeys)

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

        if let zone = change.saveZone,
           isSyncEnabled || zone != SyncZone.own {
            let id = SyncRecordID(key: change.key, zoneName: zone).recordID
            targets.append((.saveRecord(id), .deleteRecord(id)))
        }

        for zone in change.deleteZones where isSyncEnabled || zone != SyncZone.own {
            let id = SyncRecordID(key: change.key, zoneName: zone).recordID
            targets.append((.deleteRecord(id), .saveRecord(id)))
        }

        return targets
    }
}
