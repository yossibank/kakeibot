import Core
import Observation
import Store

@MainActor
@Observable
public final class SettingsHintModel {
    public let input: Input

    let dependencies: Dependencies

    public init(
        parts: ScreenParts,
        screen: SettingsScreen
    ) {
        self.input = Input(screen: screen)
        self.dependencies = Dependencies(database: parts.database)
    }
}

public extension SettingsHintModel {
    @MainActor
    @Observable
    final class Input {
        public let hint: SettingsFoldInput

        init(screen: SettingsScreen) {
            self.hint = .hint(screen)
        }
    }
}

extension SettingsHintModel {
    struct Dependencies {
        let database: AppDatabase
    }
}

extension SettingsHintModel: SettingsFoldModel {
    public func foldStore() -> SettingsFoldStore {
        SettingsFoldStore(dependencies.database)
    }
}
