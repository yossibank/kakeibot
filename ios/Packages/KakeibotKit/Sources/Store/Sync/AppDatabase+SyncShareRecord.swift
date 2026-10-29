import Foundation
import GRDB

public extension AppDatabase {
    func syncRecord(for id: SyncRecordID) async throws -> SyncRecord? {
        try await syncRecord(for: id.key).map { record in
            SyncZone.walletID(of: id.zoneName) == nil ? record : record.removingLocalColumns()
        }
    }
}

extension AppDatabase {
    static func sharedKeys(in systemFields: [SyncRecordID: Data]) -> Set<SyncKey> {
        let ids = systemFields.keys.filter { SyncZone.walletID(of: $0.zoneName) != nil }
        return Set(ids.map(\.key))
    }
}

extension SyncRecord {
    func removingLocalColumns() -> SyncRecord {
        let columns = key.table.localColumns

        guard !columns.isEmpty else {
            return self
        }

        let kept = values.filter { !columns.contains($0.key) }

        return SyncRecord(key: key, values: kept)
    }
}

private extension SyncTable {
    var localColumns: Set<String> {
        switch self {
        case .entry: ["template_id", "recurring_id", "recurring_date"]
        default: []
        }
    }
}
