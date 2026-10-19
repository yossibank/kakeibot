import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class ThemeListModel {
    public private(set) var current: ThemePreset = .navy

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
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
        }
    }
}

private extension ThemeListModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"
}
