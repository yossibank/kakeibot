import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class LaunchScreenModel: SettingSaving {
    public let state = NoticeState()
    public let input = Input()

    let dependencies: Dependencies

    public init(database: AppDatabase) {
        self.dependencies = Dependencies(database: database)
    }
}

public extension LaunchScreenModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var screen: LaunchScreen = .home
    }

    func hintFlag() -> SettingsScreenFlag {
        .closedHint(.launchScreen, in: dependencies.database)
    }

    func load() async {
        do {
            input.screen = try await dependencies.database.setting(.launchScreen)
        } catch {
            state.errorNotice.show(SettingMessage.loadFailed)
        }
    }

    func choose(_ screen: LaunchScreen) async {
        let previous = input.screen

        input.screen = screen

        await saveSetting(screen, for: .launchScreen, in: dependencies.database) {
            input.screen = previous
        }
    }
}

extension LaunchScreenModel {
    struct Dependencies {
        let database: AppDatabase
    }
}
