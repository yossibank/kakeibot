import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class ThemeListModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        parts: ScreenParts,
        appIcon: AppIconListModel
    ) {
        let input = Input()

        self.state = State(wait: parts.wait)
        self.input = input
        self.output = Output(input: input)
        self.dependencies = Dependencies(database: parts.database, appIcon: appIcon)
    }
}

public extension ThemeListModel {
    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice
        public let deletion: UndoNotice<Deletion>

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
            self.deletion = UndoNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var presented = Presented()

        public let notices: Notices

        init(wait: ScreenWait) {
            self.notices = Notices(wait: wait)
        }
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

        init(input: Input) {
            self.input = input
        }
    }
}

extension ThemeListModel {
    struct Dependencies {
        let database: AppDatabase
        let appIcon: AppIconListModel
    }
}

public extension ThemeListModel {
    func load() async {
        do {
            input.current = try await dependencies.database.setting(.theme)
            input.customThemes = try await dependencies.database.customThemes()
        } catch {
            state.notices.error.show(SettingMessage.loadFailed)
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
            state.notices.error.show(SettingMessage.saveFailed, for: error)
            return
        }

        guard let icon = AppIconChoice(choice) else {
            state.presented.suggestedIcon = nil
            return
        }

        state.presented.suggestedIcon = icon == dependencies.appIcon.input.current ? nil : icon
    }

    func use(_ icon: AppIconChoice?) async {
        state.presented.suggestedIcon = nil

        guard let icon else {
            return
        }

        await dependencies.appIcon.select(icon)
    }

    func dismissSuggestion() {
        state.presented.suggestedIcon = nil
    }

    func receive(_ deletion: Deletion) {
        state.notices.deletion.show(deletion)
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await dependencies.database.restore(deletion)
        } catch {
            state.notices.error.show(Self.restoreFailedMessage, for: error)
        }

        await load()
    }
}

private extension ThemeListModel {
    static let restoreFailedMessage = "元に戻せませんでした"
}

public extension ThemeListModel.Output {
    var currentPalette: ThemePalette {
        palette(of: input.current)
    }

    func theme(of choice: ThemeChoice) -> Theme? {
        guard case let .custom(id) = choice else {
            return nil
        }

        return input.customThemes.first { $0.id == id }
    }

    func palette(of choice: ThemeChoice) -> ThemePalette {
        switch choice {
        case .system: ThemePreset.white.palette
        case let .preset(preset): preset.palette
        case .custom: theme(of: choice)?.palette ?? ThemePreset.white.palette
        }
    }
}

extension ThemeListModel: SettingsFoldModel {
    public func foldStore() -> SettingsFoldStore {
        SettingsFoldStore(dependencies.database)
    }
}
