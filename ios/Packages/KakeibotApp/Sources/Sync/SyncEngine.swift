import CloudKit
import Foundation
import Store

public actor SyncEngine {
    let database: AppDatabase
    let scope: CKDatabase.Scope
    let container: CKContainer

    var engine: CKSyncEngine?
    var sending: [SyncKey: SyncChange] = [:]
    var owners: [String: String] = [:]
    var isSyncEnabled = false

    public init(
        database: AppDatabase,
        scope: CKDatabase.Scope,
        container: CKContainer = CKContainer(identifier: SyncEngine.containerIdentifier)
    ) {
        self.database = database
        self.scope = scope
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

        let data = try? await database.syncEngineState(isShared: isShared)

        let state = data.flatMap {
            try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: $0)
        }

        let configuration = CKSyncEngine.Configuration(
            database: cloudDatabase,
            stateSerialization: state,
            delegate: self
        )

        let engine = CKSyncEngine(configuration)

        self.engine = engine

        if state == nil,
           isSyncEnabled,
           !isShared {
            let zone = CKRecordZone(zoneID: Self.zoneID)
            engine.state.add(pendingDatabaseChanges: [.saveZone(zone)])
        }
    }

    func enqueuePending() async {
        await enqueuePending(excluding: [])
    }

    func fetchChanges() async {
        try? await engine?.fetchChanges()
    }

    func stop() {
        engine = nil
        sending = [:]
    }
}

extension SyncEngine {
    static let goneCodes: Set<CKError.Code> = [.unknownItem, .zoneNotFound]

    static var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: SyncZone.own)
    }

    var isShared: Bool {
        scope == .shared
    }

    var cloudDatabase: CKDatabase {
        container.database(with: scope)
    }

    func isForeign(_ zoneName: String) -> Bool {
        owners[zoneName] != nil
    }

    func sends(to zoneName: String) -> Bool {
        guard !isShared else {
            return isForeign(zoneName)
        }

        return !isForeign(zoneName) && (isSyncEnabled || zoneName != SyncZone.own)
    }

    func receives(from zoneName: String) -> Bool {
        guard !isShared else {
            return SyncZone.walletID(of: zoneName) != nil
        }

        return isSyncEnabled || zoneName != SyncZone.own
    }

    func recordID(of id: SyncRecordID) -> CKRecord.ID {
        let zoneID = CKRecordZone.ID(
            zoneName: id.zoneName,
            ownerName: owners[id.zoneName] ?? CKCurrentUserDefaultName
        )

        return id.key.recordID(in: zoneID)
    }

    func restart() async {
        let isSyncEnabled = isSyncEnabled
        stop()
        await start(isSyncEnabled: isSyncEnabled)
    }

    func turnOff(because reason: SyncStopReason) async {
        try? await database.turnOffSync(because: reason)
        isSyncEnabled = false
        await restart()
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
            try? await database.saveSyncEngineState(data, isShared: isShared)
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
