import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class LaunchScreenModel: SettingSaving {
    public let state: NoticeState
    public let input = Input()

    let dependencies: Dependencies

    public init(parts: ScreenParts) {
        self.state = NoticeState(wait: parts.wait)
        self.dependencies = Dependencies(database: parts.database)
    }
}

public extension LaunchScreenModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var screen: LaunchScreen = .home

        public let hint = SettingsFoldInput.hint(.launchScreen)
    }
}

extension LaunchScreenModel {
    struct Dependencies {
        let database: AppDatabase
    }
}

public extension LaunchScreenModel {
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

extension LaunchScreenModel: SettingsFoldModel {
    public func foldStore() -> SettingsFoldStore {
        SettingsFoldStore(dependencies.database)
    }
}
