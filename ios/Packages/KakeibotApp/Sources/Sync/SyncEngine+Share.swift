import CloudKit
import Core
import Foundation
import Store

public extension SyncEngine {
    static func share(
        walletID: Wallet.ID,
        title: String,
        in container: CKContainer = CKContainer(identifier: containerIdentifier)
    ) async throws -> CKShare {
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: SyncZone.wallet(walletID))
        let shareID = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneID)
        let zone = CKRecordZone(zoneID: zoneID)

        do {
            if let share = try await database.record(for: shareID) as? CKShare {
                return share
            }
        } catch let error as CKError where [.unknownItem, .zoneNotFound].contains(error.code) {}

        let share = CKShare(recordZoneID: zoneID)

        share[CKShare.SystemFieldKey.title] = title
        _ = try await database.modifyRecordZones(saving: [zone], deleting: [])

        let (saved, _) = try await database.modifyRecords(saving: [share], deleting: [])

        guard let result = saved[shareID] else {
            throw CKError(.internalError)
        }

        return try result.get() as? CKShare ?? share
    }

    static func acceptShare(
        _ metadata: CKShare.Metadata,
        in container: CKContainer = CKContainer(identifier: containerIdentifier)
    ) async throws {
        _ = try await container.accept(metadata)
    }

    static func deleteShare(
        walletID: Wallet.ID,
        in container: CKContainer = CKContainer(identifier: containerIdentifier)
    ) async throws {
        let zoneID = CKRecordZone.ID(zoneName: SyncZone.wallet(walletID))

        do {
            try await container.privateCloudDatabase.deleteRecordZone(withID: zoneID)
        } catch let error as CKError where error.code == .zoneNotFound {
            return
        }
    }

    static func leaveShare(
        walletID: Wallet.ID,
        ownerName: String,
        in container: CKContainer = CKContainer(identifier: containerIdentifier)
    ) async throws {
        let zoneID = CKRecordZone.ID(zoneName: SyncZone.wallet(walletID), ownerName: ownerName)
        let shareID = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneID)

        do {
            _ = try await container.sharedCloudDatabase.deleteRecord(withID: shareID)
        } catch let error as CKError where [.unknownItem, .zoneNotFound].contains(error.code) {
            return
        }
    }
}
