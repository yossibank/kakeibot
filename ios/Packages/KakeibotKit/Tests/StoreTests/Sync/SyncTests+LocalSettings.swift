import Foundation
@testable import Store
import Testing

extension SyncTests {
    @Test(arguments: SyncTable.localSettingKeys.sorted())
    func skipsEveryLocalSetting(_ key: String) async throws {
        let setup = try await Setup()
        let insert = "INSERT OR REPLACE INTO setting (key, value) VALUES ('\(key)', 'x')"
        let update = "UPDATE setting SET value = 'y' WHERE key = '\(key)'"
        let delete = "DELETE FROM setting WHERE key = '\(key)'"
        let localKey = SyncKey(table: .setting, id: key)

        try await setup.execute(insert)
        try await setup.execute(update)
        try await setup.execute(delete)
        let recorded = try await setup.pendingKeys()

        try await setup.execute(insert)
        try await setup.database.queueAllForSync()
        let queued = try await setup.pendingKeys()

        #expect(!recorded.contains(localKey), Self.localSettingHint)
        #expect(!queued.contains(localKey), Self.localSettingHint)
    }

    @Test(arguments: ["insert", "update", "delete"])
    func triggersSkipTheLocalSettingsOfQueue(_ event: String) async throws {
        let setup = try await Setup()
        let query = "SELECT sql FROM sqlite_master WHERE type = 'trigger' AND name = 'sync_setting_\(event)'"

        let sql = try await setup.value(query)
        let keys = Self.localSettingKeys(in: sql)

        #expect(keys == SyncTable.localSettingKeys, Self.localSettingHint)
    }
}

private extension SyncTests {
    static let localSettingHint = Comment(
        rawValue: "端末だけの設定のキーを変えたら、新しいマイグレーションでトリガーを作り直す"
    )

    static func localSettingKeys(in sql: String) -> Set<String> {
        guard
            let start = sql.range(of: "NOT IN ("),
            let end = sql[start.upperBound...].firstIndex(of: ")")
        else {
            return []
        }

        let keys = sql[start.upperBound..<end]
            .split(separator: ",")
            .map { key in
                key.trimmingCharacters(in: CharacterSet(charactersIn: " '\n"))
            }

        return Set(keys)
    }
}
