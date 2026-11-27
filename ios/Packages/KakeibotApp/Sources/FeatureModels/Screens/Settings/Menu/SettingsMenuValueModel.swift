import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class SettingsMenuValueModel<Value: Equatable & Sendable>: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        parts: ScreenParts,
        key: SettingKey<Value>
    ) {
        let state = State(wait: parts.wait)
        let input = Input(value: key.defaultValue)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: parts.database, key: key)
    }
}

public extension SettingsMenuValueModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public let errorNotice: ErrorNotice

        public internal(set) var chosen: Value?

        init(wait: ScreenWait) {
            self.errorNotice = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var value: Value

        init(value: Value) {
            self.value = value
        }
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

extension SettingsMenuValueModel {
    struct Dependencies {
        let database: AppDatabase
        let key: SettingKey<Value>
    }
}

public extension SettingsMenuValueModel {
    func load() async {
        let key = dependencies.key
        input.value = await (try? dependencies.database.setting(key)) ?? key.defaultValue
        state.chosen = nil
    }

    func choose(_ newValue: Value) async {
        state.chosen = newValue

        do {
            try await dependencies.database.setSetting(dependencies.key, to: newValue)
            input.value = newValue
        } catch {
            state.errorNotice.show(SettingMessage.saveFailed, for: error)
        }

        if state.chosen == newValue {
            state.chosen = nil
        }
    }
}

public extension SettingsMenuValueModel.Output {
    var value: Value {
        state.chosen ?? input.value
    }
}
