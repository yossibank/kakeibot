import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class ThemeListModel {
    public private(set) var current: ThemePreset = .navy
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
    func load() async {
        do {
            current = try await database.setting(.theme)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func select(_ preset: ThemePreset) async {
        guard preset != current else {
            return
        }

        let previous = current
        current = preset

        do {
            try await database.setSetting(.theme, to: preset)
        } catch {
            current = previous
            errorNotice.show(Self.saveFailedMessage)
            return
        }

        let icon = AppIconChoice(preset)
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
