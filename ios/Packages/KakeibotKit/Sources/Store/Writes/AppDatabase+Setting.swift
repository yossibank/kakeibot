import Core
import GRDB

public extension AppDatabase {
    func setSetting<Value>(
        _ key: SettingKey<Value>,
        to value: Value
    ) async throws {
        try await writer.write { db in
            try Self.setSetting(key, to: value, in: db)
        }
    }
}

extension AppDatabase {
    static func setSetting<Value>(
        _ key: SettingKey<Value>,
        to value: Value,
        in db: Database
    ) throws {
        guard let text = key.encode(value) else {
            _ = try Setting.deleteOne(db, key: key.key)

            return
        }

        let setting = Setting(key: key.key, value: text)

        try setting.save(db)
    }
}
