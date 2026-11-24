import Store

@MainActor
public protocol SettingsBoardDatabaseModel: SettingsBoardListModel {
    init(
        database: AppDatabase,
        clock: ScreenClock
    )
}
