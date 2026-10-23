import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class ThemeListModel {
    public private(set) var current: ThemeChoice = .system
    public private(set) var customThemes: [Theme] = []
    public private(set) var suggestedIcon: AppIconChoice?

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase
    private let appIcon: AppIconListModel

    public init(
        database: AppDatabase,
        appIcon: AppIconListModel
    ) {
        self.database = database
        self.appIcon = appIcon
    }
}

public extension ThemeListModel {
    var currentPalette: ThemePalette {
        switch current {
        case .system:
            return ThemePreset.white.palette
        case let .preset(preset):
            return preset.palette
        case let .custom(id):
            let theme = customThemes.first { $0.id == id }
            return theme?.palette ?? ThemePreset.white.palette
        }
    }

    func load() async {
        do {
            current = try await database.setting(.theme)
            customThemes = try await database.customThemes()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func select(_ choice: ThemeChoice) async {
        guard choice != current else {
            return
        }

        let previous = current

        current = choice

        do {
            try await database.setSetting(.theme, to: choice)
        } catch {
            current = previous

            errorNotice.show(Self.saveFailedMessage)

            return
        }

        guard let icon = AppIconChoice(choice) else {
            suggestedIcon = nil

            return
        }

        suggestedIcon = icon == appIcon.current ? nil : icon
    }

    func use(_ icon: AppIconChoice?) async {
        suggestedIcon = nil

        guard let icon else {
            return
        }

        await appIcon.select(icon)
    }

    func dismissSuggestion() {
        suggestedIcon = nil
    }
}

private extension ThemeListModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"
}
