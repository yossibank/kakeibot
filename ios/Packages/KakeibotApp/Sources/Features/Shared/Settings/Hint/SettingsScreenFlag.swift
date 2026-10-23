import Core
import Observation
import Store

@MainActor
@Observable
public final class SettingsScreenFlag {
    public private(set) var isOn: Bool
    public private(set) var isLoaded = false

    private let database: AppDatabase
    private let key: SettingKey<Set<SettingsScreen>>
    private let screen: SettingsScreen
    private let savesOn: Bool

    public init(
        database: AppDatabase,
        key: SettingKey<Set<SettingsScreen>>,
        screen: SettingsScreen,
        isOn: Bool = false,
        savesOn: Bool = true
    ) {
        self.database = database
        self.key = key
        self.screen = screen
        self.isOn = isOn
        self.savesOn = savesOn
    }
}

public extension SettingsScreenFlag {
    static func closedHint(
        _ screen: SettingsScreen,
        in database: AppDatabase
    ) -> SettingsScreenFlag {
        SettingsScreenFlag(
            database: database,
            key: .closedHints,
            screen: screen,
            isOn: true
        )
    }

    static func openHiddenList(
        _ screen: SettingsScreen,
        in database: AppDatabase
    ) -> SettingsScreenFlag {
        SettingsScreenFlag(
            database: database,
            key: .closedHiddenLists,
            screen: screen,
            isOn: true,
            savesOn: false
        )
    }

    func load() async {
        let screens = try? await database.setting(key)
        let isSaved = screens?.contains(screen) ?? false

        isOn = isSaved == savesOn
        isLoaded = true
    }

    func set(_ isOn: Bool) -> Task<Void, Never> {
        self.isOn = isOn

        return Task {
            await save(isOn)
        }
    }
}

private extension SettingsScreenFlag {
    func save(_ isOn: Bool) async {
        var screens = await (try? database.setting(key)) ?? []

        if isOn == savesOn {
            screens.insert(screen)
        } else {
            screens.remove(screen)
        }

        try? await database.setSetting(key, to: screens)
    }
}
