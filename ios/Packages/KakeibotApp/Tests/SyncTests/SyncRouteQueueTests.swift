@testable import Store
@testable import Sync
import Testing

struct SyncRouteQueueTests {
    @Test
    func queuesSaveAndDeletionOfItsOldZone() {
        let change = Self.change(saveZone: Self.ownWallet, deleteZones: [SyncZone.own])

        let plan = Self.route.enqueue([change], pending: [])

        #expect(plan.added == [
            .save(Self.id(in: Self.ownWallet)),
            .delete(Self.id(in: SyncZone.own))
        ])
        #expect(plan.removed.isEmpty)
        #expect(plan.dropped.isEmpty)
    }

    @Test
    func replacesQueuedSaveWithDeletionWhenRowIsDeletedBeforeItIsSent() {
        let change = Self.change(saveZone: nil, deleteZones: [])
        let own = Self.id(in: SyncZone.own)
        let wallet = Self.id(in: Self.ownWallet)

        let plan = Self.route.enqueue([change], pending: [.save(own), .save(wallet)])

        #expect(Set(plan.added) == [.delete(own), .delete(wallet)])
        #expect(Set(plan.removed) == [.save(own), .save(wallet)])
        #expect(plan.dropped.isEmpty)
    }

    @Test
    func replacesQueuedSaveOnceWhenItsZoneIsAlreadyRecorded() {
        let change = Self.change(saveZone: nil, deleteZones: [SyncZone.own])
        let own = Self.id(in: SyncZone.own)

        let plan = Self.route.enqueue([change], pending: [.save(own)])

        #expect(plan.added == [.delete(own)])
        #expect(plan.removed == [.save(own)])
    }

    @Test
    func sendsUnrecordedDeletionToOwnZoneWhenNoSaveIsQueued() {
        let change = Self.change(saveZone: nil, deleteZones: [])

        let plan = Self.route.enqueue([change], pending: [])

        #expect(plan.added == [.delete(Self.id(in: SyncZone.own))])
        #expect(plan.dropped.isEmpty)
    }

    @Test
    func dropsUnrecordedDeletionWhileSyncIsOff() {
        let change = Self.change(saveZone: nil, deleteZones: [])
        let off = SyncRoute(isShared: false, isSyncEnabled: false, knowsZones: true, owners: [:])

        let plan = off.enqueue([change], pending: [])

        #expect(plan.added.isEmpty)
        #expect(plan.dropped == [change])
    }

    @Test
    func leavesQueuedChangesAsTheyAre() {
        let saving = Self.change(saveZone: SyncZone.own, deleteZones: [])
        let deleting = Self.change(saveZone: nil, deleteZones: [SyncZone.own])
        let own = Self.id(in: SyncZone.own)

        let saved = Self.route.enqueue([saving], pending: [.save(own)])
        let deleted = Self.route.enqueue([deleting], pending: [.delete(own)])

        #expect(saved == SyncRoute.Enqueue(added: [], removed: [], dropped: []))
        #expect(deleted == SyncRoute.Enqueue(added: [], removed: [], dropped: []))
    }

    @Test
    func replacesQueuedDeletionWithSaveWhenRowIsRestored() {
        let change = Self.change(saveZone: SyncZone.own, deleteZones: [])
        let own = Self.id(in: SyncZone.own)

        let plan = Self.route.enqueue([change], pending: [.delete(own)])

        #expect(plan.added == [.save(own)])
        #expect(plan.removed == [.delete(own)])
    }
}

private extension SyncRouteQueueTests {
    static let key = SyncKey(table: .entry, id: "e")
    static let ownWallet = SyncZone.wallet(.init())
    static let route = SyncRoute(
        isShared: false,
        isSyncEnabled: true,
        knowsZones: true,
        owners: [:]
    )

    static func id(in zoneName: String) -> SyncRecordID {
        SyncRecordID(key: key, zoneName: zoneName)
    }

    static func change(
        saveZone: String?,
        deleteZones: [String]
    ) -> SyncChange {
        SyncChange(
            key: key,
            isDeletion: saveZone == nil,
            saveZone: saveZone,
            deleteZones: deleteZones,
            version: 1
        )
    }
}
