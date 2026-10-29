import CloudKit
import Store
@testable import Sync
import Testing

struct SyncRecordTests {
    @Test
    func roundTripsRecordName() {
        let key = SyncKey(table: .noSpendDay, id: "2026-10-01")
        let zoneID = CKRecordZone.ID(zoneName: "Kakeibot")
        let recordID = key.recordID(in: zoneID)

        #expect(recordID.recordName == "no_spend_day/2026-10-01")
        #expect(SyncKey(recordID) == key)
    }

    @Test
    func roundTripsValuesWithNull() throws {
        let key = SyncKey(table: .wallet, id: "w")
        let zoneID = CKRecordZone.ID(zoneName: "Kakeibot")

        let local = SyncRecord(
            key: key,
            values: [
                "name": .text("財布"),
                "balance": .integer(100),
                "memo": .null
            ]
        )

        let record = try local.record(in: zoneID, systemFields: nil)

        #expect(record.recordType == "wallet")
        #expect(SyncRecord(record) == local)
    }

    @Test
    func keepsSystemFields() throws {
        let zoneID = CKRecordZone.ID(zoneName: "Kakeibot")
        let key = SyncKey(table: .tag, id: "t")
        let local = SyncRecord(key: key, values: [:])
        let first = try local.record(in: zoneID, systemFields: nil)

        let second = try local.record(in: zoneID, systemFields: first.systemFields)

        #expect(second.recordID == first.recordID)
        #expect(second.recordType == first.recordType)
    }

    @Test
    func ignoresUnknownRecordName() {
        let recordID = CKRecord.ID(recordName: "unknown/1")

        #expect(SyncKey(recordID) == nil)
    }
}
