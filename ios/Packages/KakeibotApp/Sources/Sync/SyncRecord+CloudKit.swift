import CloudKit
import Foundation
import Store

extension SyncKey {
    init?(_ recordID: CKRecord.ID) {
        let parts = recordID.recordName.split(separator: "/", maxSplits: 1)

        guard
            parts.count == 2,
            let table = SyncTable(rawValue: String(parts[0]))
        else {
            return nil
        }

        let id = String(parts[1])

        self.init(table: table, id: id)
    }

    func recordID(in zoneID: CKRecordZone.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: "\(table.rawValue)/\(id)", zoneID: zoneID)
    }
}

extension SyncRecordID {
    init?(_ recordID: CKRecord.ID) {
        guard let key = SyncKey(recordID) else {
            return nil
        }

        self.init(key: key, zoneName: recordID.zoneID.zoneName)
    }
}

extension SyncRecord {
    static let fieldsKey = "fields"

    init?(_ record: CKRecord) {
        guard
            let key = SyncKey(record.recordID),
            let fields = record.encryptedValues[Self.fieldsKey] as? String,
            let values = try? JSONDecoder().decode(
                [String: SyncValue].self,
                from: Data(fields.utf8)
            )
        else {
            return nil
        }

        self.init(key: key, values: values)
    }

    func record(
        in zoneID: CKRecordZone.ID,
        systemFields: Data?
    ) throws -> CKRecord {
        let recordID = key.recordID(in: zoneID)
        let data = try JSONEncoder().encode(values)

        let record = systemFields.flatMap(CKRecord.init(systemFields:))
            ?? CKRecord(recordType: key.table.rawValue, recordID: recordID)

        let fields = String(decoding: data, as: UTF8.self)

        record.encryptedValues[Self.fieldsKey] = fields

        return record
    }
}

extension CKRecord {
    var systemFields: Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)

        encodeSystemFields(with: coder)
        coder.finishEncoding()

        return coder.encodedData
    }

    convenience init?(systemFields: Data) {
        guard let coder = try? NSKeyedUnarchiver(forReadingFrom: systemFields) else {
            return nil
        }

        coder.requiresSecureCoding = true

        defer {
            coder.finishDecoding()
        }

        self.init(coder: coder)
    }
}
