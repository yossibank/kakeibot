import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class DeletionUndo {
    public var deletion: Deletion?
    public var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension DeletionUndo {
    func restore(_ deletion: Deletion) async {
        do {
            try await database.restore(deletion)
        } catch {
            errorNotice.show(Self.restoreFailedMessage)
        }
    }
}

private extension DeletionUndo {
    static let restoreFailedMessage = "元に戻せませんでした"
}
