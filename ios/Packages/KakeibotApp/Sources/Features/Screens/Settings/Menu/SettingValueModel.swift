import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class SettingValueModel<Value: Equatable & Sendable> {
    public private(set) var value: Value

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase
    private let key: SettingKey<Value>

    private var savedValue: Value

    public init(
        database: AppDatabase,
        key: SettingKey<Value>
    ) {
        self.database = database
        self.key = key
        self.value = key.defaultValue
        self.savedValue = key.defaultValue
    }
}

public extension SettingValueModel {
    func load() async {
        value = await (try? database.setting(key)) ?? key.defaultValue
        savedValue = value
    }

    func choose(_ newValue: Value) async {
        value = newValue

        do {
            try await database.setSetting(key, to: newValue)
            savedValue = newValue
        } catch {
            if value == newValue {
                value = savedValue
            }

            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }
}

private extension SettingValueModel {
    static var saveFailedMessage: String {
        "設定を保存できませんでした"
    }
}
