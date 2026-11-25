import Core
import Observation
import Store

@MainActor
@Observable
public final class SettingsFoldInput {
    public internal(set) var isClosed: Bool?

    let key: SettingKey<Set<SettingsScreen>>
    let screen: SettingsScreen

    init(
        key: SettingKey<Set<SettingsScreen>>,
        screen: SettingsScreen
    ) {
        self.key = key
        self.screen = screen
    }
}

extension SettingsFoldInput {
    static func hint(_ screen: SettingsScreen) -> SettingsFoldInput {
        SettingsFoldInput(key: .closedHints, screen: screen)
    }

    static func hiddenList(_ screen: SettingsScreen) -> SettingsFoldInput {
        SettingsFoldInput(key: .closedHiddenLists, screen: screen)
    }
}
