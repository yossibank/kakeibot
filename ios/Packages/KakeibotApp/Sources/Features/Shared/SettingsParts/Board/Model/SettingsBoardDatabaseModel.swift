import Store

@MainActor
protocol SettingsBoardDatabaseModel: SettingsBoardListModel {
    init(
        database: AppDatabase,
        clock: ScreenClock
    )
}
