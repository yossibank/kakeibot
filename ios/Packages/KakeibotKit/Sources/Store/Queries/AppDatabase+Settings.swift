import Core
import GRDB

public extension AppDatabase {
    func settingUpdates<Value: Equatable>(
        _ key: SettingKey<Value>
    ) -> some AsyncSequence<Value, any Error> {
        ValueObservation
            .tracking { db in
                try Self.setting(key, in: db)
            }
            .removeDuplicates()
            .values(in: writer)
    }

    func setting<Value>(_ key: SettingKey<Value>) async throws -> Value {
        try await writer.read { db in
            try Self.setting(key, in: db)
        }
    }
}

extension AppDatabase {
    static func setting<Value>(
        _ key: SettingKey<Value>,
        in db: Database
    ) throws -> Value {
        let setting = try Setting.fetchOne(db, key: key.key)

        return setting.flatMap { key.decode($0.value) } ?? key.defaultValue
    }
}
