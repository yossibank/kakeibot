import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class DeletionUndo: ScreenPerforming {
    public let state: State

    let dependencies: Dependencies

    public init(parts: ScreenParts) {
        self.state = State()
        self.dependencies = Dependencies(database: parts.database)
    }
}

public extension DeletionUndo {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()
        public var deletion: Deletion?
    }
}

extension DeletionUndo {
    struct Dependencies {
        let database: AppDatabase
    }
}

public extension DeletionUndo {
    func restore(_ deletion: Deletion) async {
        do {
            try await dependencies.database.restore(deletion)
        } catch {
            state.errorNotice.show(Self.restoreFailedMessage, for: error)
        }
    }
}

private extension DeletionUndo {
    static let restoreFailedMessage = "元に戻せませんでした"
}
