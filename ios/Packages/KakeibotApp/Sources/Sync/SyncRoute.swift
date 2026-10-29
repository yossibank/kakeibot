import CloudKit
import Store

struct SyncRoute: Sendable {
    let isShared: Bool
    let isSyncEnabled: Bool
    let owners: [String: String]
}

extension SyncRoute {
    struct Finish: Equatable {
        let finished: [SyncChange]
        let staleDeletions: [SyncRecordID]
    }

    enum Retry: Equatable {
        case resolveConflict
        case saveZoneAgain
        case sendAgain
        case skip
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

    func finish(
        sending: [SyncKey: SyncChange],
        saved: [SyncRecordID],
        deleted: [SyncRecordID]
    ) -> Finish {
        var sending = sending
        var finished: [SyncChange] = []
        var staleDeletions: [SyncRecordID] = []

        for id in saved {
            guard
                let change = sending[id.key],
                change.saveZone == id.zoneName
            else {
                continue
            }

            let stale = change.deleteZones
                .filter { sends(to: $0) }
                .map { SyncRecordID(key: change.key, zoneName: $0) }

            sending.removeValue(forKey: id.key)
            finished.append(change)
            staleDeletions.append(contentsOf: stale)
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

        return Finish(finished: finished, staleDeletions: staleDeletions)
    }

    func retry(after code: CKError.Code) -> Retry {
        switch code {
        case .serverRecordChanged: .resolveConflict
        case .zoneNotFound: isShared ? .skip : .saveZoneAgain
        case .unknownItem: .sendAgain
        default: .skip
        }
    }
}
