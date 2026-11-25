import Store

public struct SettingsFoldStore: Sendable {
    let database: AppDatabase

    init(_ database: AppDatabase) {
        self.database = database
    }
}
