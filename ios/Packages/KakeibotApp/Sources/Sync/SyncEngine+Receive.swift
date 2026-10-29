import CloudKit
import Foundation
import Store

extension SyncEngine {
    func changeAccount(_ change: CKSyncEngine.Event.AccountChange) async {
        switch change.changeType {
        case .signIn:
            guard !isShared else {
                return
            }

            try? await database.queueAllForSync()
        case .signOut, .switchAccounts:
            await isShared ? leaveShares() : turnOff()
        @unknown default:
            break
        }
    }

    func deleteZone(_ deletion: CKDatabase.DatabaseChange.Deletion) async {
        guard
            !isShared,
            deletion.zoneID == Self.zoneID
        else {
            if let walletID = SyncZone.walletID(of: deletion.zoneID.zoneName),
               await isGone(deletion.zoneID) {
                try? await database.endSharing(walletID)
            }

            return
        }

        switch deletion.reason {
        case .encryptedDataReset:
            try? await database.resetSync(isShared: false)
            await restart()
            try? await database.queueAllForSync()
        default:
            await turnOff()
        }
    }

    func applyFetched(_ changes: CKSyncEngine.Event.FetchedRecordZoneChanges) async {
        let records = changes.modifications
            .map(\.record)
            .filter { receives(from: $0.recordID.zoneID.zoneName) }
        let saved = records.compactMap(SyncRecord.init)
        let deleted = changes.deletions
            .compactMap { SyncRecordID($0.recordID) }
            .filter { receives(from: $0.zoneName) }
        let systemFields = records.reduce(into: [SyncRecordID: Data]()) { fields, record in
            if let id = SyncRecordID(record.recordID) {
                fields[id] = record.systemFields
            }
        }
        let owners = records.reduce(into: [String: String]()) { owners, record in
            if isShared {
                owners[record.recordID.zoneID.zoneName] = record.recordID.zoneID.ownerName
            }
        }

        do {
            try await database.applySyncChanges(
                saved: saved,
                deleted: deleted,
                systemFields: systemFields,
                owners: owners
            )
        } catch {
            try? await database.resetSync(isShared: isShared)
            await restart()
        }
    }
}

private extension SyncEngine {
    func leaveShares() async {
        let owners = await (try? database.syncShareOwners()) ?? [:]

        try? await database.resetSync(isShared: true)

        for walletID in owners.keys.compactMap(SyncZone.walletID) {
            try? await database.endSharing(walletID)
        }

        await restart()
    }

    func isGone(_ zoneID: CKRecordZone.ID) async -> Bool {
        do {
            _ = try await cloudDatabase.recordZone(for: zoneID)
            return false
        } catch let error as CKError where error.code == .zoneNotFound {
            return true
        } catch {
            return false
        }
    }
}
