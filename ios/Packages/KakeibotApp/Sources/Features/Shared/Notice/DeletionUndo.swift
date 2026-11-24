import Core
import DesignSystem
import FeatureModels
import Observation
import Store

@MainActor
@Observable
public final class DeletionUndo {
    public let state: State

    let dependencies: Dependencies

    public init(database: AppDatabase) {
        self.state = State()
        self.dependencies = Dependencies(database: database)
    }
}

public extension DeletionUndo {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()

        public var deletion: Deletion?
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await dependencies.database.restore(deletion)
        } catch {
            state.errorNotice.show(Self.restoreFailedMessage, for: error)
        }
    }
}

extension DeletionUndo {
    struct Dependencies {
        let database: AppDatabase
    }
}

private extension DeletionUndo {
    static let restoreFailedMessage = "元に戻せませんでした"
}
