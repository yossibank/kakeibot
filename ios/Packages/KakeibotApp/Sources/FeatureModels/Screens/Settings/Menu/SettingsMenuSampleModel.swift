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
    enum Progress: Hashable, Sendable {
        case inserting
        case inserted
        case failed
    }

    @MainActor
    @Observable
    final class State {
        public var isConfirming = false

        public internal(set) var progress: Progress?
    }

    func insert(today: LocalDate) async {
        state.progress = .inserting

        do {
            try await SettingsMenuSampleData.insert(
                into: dependencies.database,
                today: today,
                now: dependencies.clock.now
            )

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
        case .inserting: nil
        case .inserted: "テストデータを入れました"
        case .failed: "テストデータを入れられませんでした"
        }
    }
}
