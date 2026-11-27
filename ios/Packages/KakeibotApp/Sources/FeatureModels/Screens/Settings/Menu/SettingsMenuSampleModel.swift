#if DEBUG
import Core
import Observation

@MainActor
@Observable
public final class SettingsMenuSampleModel: ScreenPerforming {
    public let state = State()

    let dependencies: ScreenParts

    init(parts: ScreenParts) {
        self.dependencies = parts
    }
}

public extension SettingsMenuSampleModel {
    enum Prompt: Hashable, Sendable {
        case insert
    }

    enum Progress: Hashable, Sendable {
        case inserted
        case failed
    }

    struct Presented: ScreenEditable {
        public var prompt = Shown<Prompt>()
    }

    @MainActor
    @Observable
    final class State {
        public var presented = Presented()

        public internal(set) var progress: Progress?

        public let task = ModelTask()
    }

    func insert(today: LocalDate) async {
        guard !state.task.isRunning else {
            return
        }

        state.progress = nil

        do {
            try await state.task.attempt {
                try await SettingsMenuSampleData.insert(
                    into: dependencies.database,
                    today: today,
                    now: dependencies.clock.now
                )
            }

            state.progress = .inserted
        } catch {
            state.progress = .failed
        }
    }
}
#endif

public extension SettingsMenuSampleModel.Progress {
    var message: String? {
        switch self {
        case .inserted: "テストデータを入れました"
        case .failed: "テストデータを入れられませんでした"
        }
    }
}
