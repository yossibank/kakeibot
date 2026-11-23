import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class LaunchScreenModel: SettingSaving {
    public private(set) var screen: LaunchScreen = .home

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension LaunchScreenModel {
    func hintFlag() -> SettingsScreenFlag {
        .closedHint(.launchScreen, in: database)
    }

    func load() async {
        do {
            screen = try await database.setting(.launchScreen)
        } catch {
            errorNotice.show(SettingMessage.loadFailed)
        }
    }

    func choose(_ screen: LaunchScreen) async {
        let previous = self.screen

        self.screen = screen

        await saveSetting(screen, for: .launchScreen, in: database) {
            self.screen = previous
        }
    }
}
