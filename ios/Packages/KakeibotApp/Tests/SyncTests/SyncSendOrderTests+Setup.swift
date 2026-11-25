import Core
import Foundation
@testable import Store
@testable import Sync
import Testing

extension SyncSendOrderTests {
    struct Batch {
        let saves: [SyncRecordID: SyncRecord]
        let deletes: [SyncRecordID]
    }

    final class Device {
        let database: AppDatabase

        var pending: Set<SyncRoute.Pending> = []
        var sending: [SyncKey: SyncChange] = [:]
        var cloud: [SyncRecordID: SyncRecord] = [:]

        init(database: AppDatabase) {
            self.database = database
        }
    }
}

extension SyncSendOrderTests.Batch {
    var sent: Set<SyncRoute.Pending> {
        let saved = saves.keys.map(SyncRoute.Pending.save)
        let deleted = deletes.map(SyncRoute.Pending.delete)
        return Set(saved + deleted)
    }
}

extension SyncSendOrderTests.Device {
    static let now = Date(timeIntervalSince1970: 1_791_000_000)
    static let date = LocalDate(now, in: .gmt)
    static let route = SyncRoute(
        isShared: false,
        isSyncEnabled: true,
        knowsZones: true,
        owners: [:]
    )
    static let maxRounds = 10

    var waitingKeys: [SyncKey] {
        get async throws {
            try await database.pendingSyncChanges().map(\.key)
        }
    }

    static func syncing() async throws -> SyncSendOrderTests.Device {
        let database = try AppDatabase.inMemory()

        try database.insertDefaultsIfEmpty(at: now)
        try await database.turnOnSync()

        let device = SyncSendOrderTests.Device(database: database)

        try await device.sync()

        return device
    }

    func saveEntry(
        amount: Int = 500,
        editing id: Entry.ID? = nil
    ) async throws -> Entry {
        let options = try await database.entryOptions()

        let draft = EntryDraft(
            type: .expense,
            amount: amount,
            date: Self.date,
            categoryId: options.expenseCategories.first?.id,
            walletId: options.wallets[0].id
        )

        return try await database.saveEntry(draft, editing: id, at: Self.now)
    }

    func enqueue() async throws {
        let changes = try await database.pendingSyncChanges()
        let plan = Self.route.enqueue(changes, pending: pending)

        pending.subtract(plan.removed)
        pending.formUnion(plan.added)

        try await database.removeSyncChanges(plan.dropped)
    }

    func takeBatch() async throws -> SyncSendOrderTests.Batch? {
        for change in try await database.pendingSyncChanges() {
            sending[change.key] = change
        }

        var saves: [SyncRecordID: SyncRecord] = [:]
        var deletes: [SyncRecordID] = []
        var missing: [SyncRoute.Pending] = []

        for change in pending {
            switch change {
            case let .save(id):
                if let record = try await database.syncRecord(for: id),
                   try await database.syncSaveZone(for: id.key) == id.zoneName {
                    saves[id] = record
                } else {
                    missing.append(change)
                }

            case let .delete(id):
                deletes.append(id)
            }
        }

        try await database.noteSyncSends(Array(saves.keys))

        if !missing.isEmpty {
            pending.subtract(missing)
            try await enqueue()
        }

        guard !saves.isEmpty || !deletes.isEmpty else {
            return nil
        }

        return SyncSendOrderTests.Batch(saves: saves, deletes: deletes)
    }

    func arrive(_ batch: SyncSendOrderTests.Batch) {
        cloud.merge(batch.saves) { _, sent in
            sent
        }

        for id in batch.deletes {
            cloud.removeValue(forKey: id)
        }
    }

    func finish(_ batch: SyncSendOrderTests.Batch) async throws {
        let fields = batch.saves.mapValues { _ in Data([1]) }

        let result = Self.route.finish(
            sending: sending,
            saved: Array(batch.saves.keys),
            deleted: batch.deletes
        )

        pending.subtract(batch.sent)

        for change in result.finished {
            sending.removeValue(forKey: change.key)
        }

        for id in result.staleDeletions {
            pending.insert(.delete(id))
        }

        try await database.saveSyncSystemFields(fields)
        try await database.removeSyncSystemFields(batch.deletes)
        try await database.removeSyncChanges(result.finished)
        try await enqueue()
    }

    func deliver(_ batch: SyncSendOrderTests.Batch) async throws {
        arrive(batch)

        try await finish(batch)
    }

    func relaunch(keepingEngineState: Bool) async throws {
        sending = [:]

        if !keepingEngineState {
            pending = []
        }

        try await enqueue()
    }

    func fetch() async throws {
        try await database.applySyncChanges(
            saved: Array(cloud.values),
            deleted: [],
            systemFields: cloud.mapValues { _ in Data([1]) },
            at: Self.now
        )
    }

    func sync() async throws {
        for _ in 0..<Self.maxRounds {
            try await enqueue()

            if let batch = try await takeBatch() {
                try await deliver(batch)
            } else if pending.isEmpty {
                return
            }
        }

        Issue.record("\(Self.maxRounds) 回送っても、送るものが残った")
    }
}

extension Entry {
    var syncKey: SyncKey {
        SyncKey(table: .entry, id: id.description)
    }

    var ownRecordID: SyncRecordID {
        syncKey.recordID(in: SyncZone.own)
    }
}

private extension SyncKey {
    func recordID(in zoneName: String) -> SyncRecordID {
        SyncRecordID(key: self, zoneName: zoneName)
    }
}
