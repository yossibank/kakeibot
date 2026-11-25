import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class ThemeListModel {
    public let state = State()
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        parts: ScreenParts,
        appIcon: AppIconListModel
    ) {
        let input = Input()

        self.input = input
        self.output = Output(input: input)
        self.dependencies = Dependencies(database: parts.database, appIcon: appIcon)
    }
}

public extension ThemeListModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()
        public var deletion: Deletion?

        public internal(set) var suggestedIcon: AppIconChoice?
        public internal(set) var presented: Presented?
        public internal(set) var pressing: ThemeChoice?
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var current: ThemeChoice = .system
        public internal(set) var customThemes: [Theme] = []

        public let hint = SettingsFoldInput.hint(.themes)
    }

    @MainActor
    final class Output {
        let input: Input

        public var currentPalette: ThemePalette {
            palette(of: input.current)
        }

        init(input: Input) {
            self.input = input
        }

        public func theme(of choice: ThemeChoice) -> Theme? {
            guard case let .custom(id) = choice else {
                return nil
            }

            return input.customThemes.first { $0.id == id }
        }

        public func palette(of choice: ThemeChoice) -> ThemePalette {
            switch choice {
            case .system: ThemePreset.white.palette
            case let .preset(preset): preset.palette
            case .custom: theme(of: choice)?.palette ?? ThemePreset.white.palette
            }
        }
    }

    func load() async {
        do {
            input.current = try await dependencies.database.setting(.theme)
            input.customThemes = try await dependencies.database.customThemes()
        } catch {
            state.errorNotice.show(SettingMessage.loadFailed)
        }
    }

    func select(_ choice: ThemeChoice) async {
        guard choice != input.current else {
            return
        }

        let previous = input.current

        input.current = choice

        do {
            try await dependencies.database.setSetting(.theme, to: choice)
        } catch {
            input.current = previous
            state.errorNotice.show(SettingMessage.saveFailed, for: error)
            return
        }

        guard let icon = AppIconChoice(choice) else {
            state.suggestedIcon = nil
            return
        }

        state.suggestedIcon = icon == dependencies.appIcon.input.current ? nil : icon
    }

    func use(_ icon: AppIconChoice?) async {
        state.suggestedIcon = nil

        guard let icon else {
            return
        }

        await dependencies.appIcon.select(icon)
    }

    func dismissSuggestion() {
        state.suggestedIcon = nil
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await dependencies.database.restore(deletion)
        } catch {
            state.errorNotice.show(Self.restoreFailedMessage, for: error)
        }

        await load()
    }
}

extension ThemeListModel {
    struct Dependencies {
        let database: AppDatabase
        let appIcon: AppIconListModel
    }
}

private extension ThemeListModel {
    static let restoreFailedMessage = "元に戻せませんでした"
}

extension ThemeListModel: SettingsFoldModel {
    public func foldStore() -> SettingsFoldStore {
        SettingsFoldStore(dependencies.database)
    }
}
