import CloudKit
import Store

extension SyncRoute {
    enum Pending: Hashable {
        case save(SyncRecordID)
        case delete(SyncRecordID)
    }

    struct Enqueue: Equatable {
        let added: [Pending]
        let removed: [Pending]
        let dropped: [SyncChange]
    }

    func enqueue(
        _ changes: [SyncChange],
        pending: Set<Pending>
    ) -> Enqueue {
        let saving = Set(pending.compactMap(\.savedKey))

        var added: [Pending] = []
        var removed: [Pending] = []
        var dropped: [SyncChange] = []

        for change in changes {
            var targets = targets(of: change)

            if targets.isEmpty,
               !saving.contains(change.key) {
                if let zone = unsentDeletionZone(of: change) {
                    targets = [.delete(SyncRecordID(key: change.key, zoneName: zone))]
                } else if drops(change) {
                    dropped.append(change)
                }
            }

            for wanted in targets where !pending.contains(wanted) {
                added.append(wanted)

                if pending.contains(wanted.opposite) {
                    removed.append(wanted.opposite)
                }
            }
        }

        return Enqueue(added: added, removed: removed, dropped: dropped)
    }
}

extension SyncRoute.Pending {
    var opposite: Self {
        switch self {
        case let .save(id): .delete(id)
        case let .delete(id): .save(id)
        }
    }

    init?(_ change: CKSyncEngine.PendingRecordZoneChange) {
        switch change {
        case let .saveRecord(recordID):
            guard let id = SyncRecordID(recordID) else {
                return nil
            }

            self = .save(id)

        case let .deleteRecord(recordID):
            guard let id = SyncRecordID(recordID) else {
                return nil
            }

            self = .delete(id)

        @unknown default:
            return nil
        }
    }
}

private extension SyncRoute {
    func targets(of change: SyncChange) -> [Pending] {
        var targets: [Pending] = []

        if let zone = change.saveZone,
           sends(to: zone) {
            targets.append(.save(SyncRecordID(key: change.key, zoneName: zone)))
        }

        for zone in change.deleteZones where sends(to: zone) {
            targets.append(.delete(SyncRecordID(key: change.key, zoneName: zone)))
        }

        return targets
    }
}

private extension SyncRoute.Pending {
    var savedKey: SyncKey? {
        guard case let .save(id) = self else {
            return nil
        }

        return id.key
    }
}
