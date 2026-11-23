import DesignSystem
import Store

@MainActor
protocol SettingSaving: AnyObject {
    var errorNotice: ErrorNotice { get set }
}

extension SettingSaving {
    func saveSetting<Value: Sendable>(
        _ value: Value,
        for key: SettingKey<Value>,
        in database: AppDatabase,
        rollback: () -> Void
    ) async {
        do {
            try await database.setSetting(key, to: value)
        } catch {
            rollback()
            errorNotice.show(SettingMessage.saveFailed, for: error)
        }
    }
}
