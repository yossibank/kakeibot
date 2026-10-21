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

    public init(
        database: AppDatabase,
        key: SettingKey<Set<SettingsScreen>>,
        screen: SettingsScreen,
        isOn: Bool = false
    ) {
        self.database = database
        self.key = key
        self.screen = screen
        self.isOn = isOn
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
            key: .openHiddenLists,
            screen: screen,
            isOn: true
        )
    }

    func load() async {
        let screens = try? await database.setting(key)
        isOn = screens?.contains(screen) ?? false
        isLoaded = true
    }

    @discardableResult
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

        if isOn {
            screens.insert(screen)
        } else {
            screens.remove(screen)
        }

        try? await database.setSetting(key, to: screens)
    }
}
