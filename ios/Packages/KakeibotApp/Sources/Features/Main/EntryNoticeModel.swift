import Core
import Observation
import Store

@MainActor
@Observable
public final class EntryNoticeModel {
    public private(set) var change: EntryChange?
    public private(set) var errorMessage: String?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension EntryNoticeModel {
    var isShown: Bool {
        change != nil || errorMessage != nil
    }

    func show(_ change: EntryChange) {
        errorMessage = nil
        self.change = change
    }

    func undo() async {
        guard let change else {
            return
        }

        self.change = nil

        do {
            switch change.kind {
            case .recorded:
                try await database.deleteEntry(change.entry.id)
            case let .edited(previous):
                try await database.restoreEntry(previous)
            case .deleted:
                try await database.restoreEntry(change.entry)
            }
        } catch {
            errorMessage = Self.undoFailedMessage
        }
    }

    func clear() {
        change = nil
        errorMessage = nil
    }
}

private extension EntryNoticeModel {
    static let undoFailedMessage = "取り消せませんでした"
}
