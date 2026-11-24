import Store

@MainActor
public protocol SettingsBoardDatabaseModel: SettingsBoardListModel {
    init(parts: ScreenParts)
}
