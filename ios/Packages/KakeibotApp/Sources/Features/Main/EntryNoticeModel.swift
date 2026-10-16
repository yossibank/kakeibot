import Core
import Observation
import Store

@MainActor
@Observable
public final class EntryNoticeModel {
    public private(set) var notice: Notice?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension EntryNoticeModel {
    enum Notice: Hashable, Sendable {
        case changed(EntryChange)
        case undone
        case undoFailed
    }

    var change: EntryChange? {
        if case let .changed(change) = notice {
            change
        } else {
            nil
        }
    }

    func show(_ change: EntryChange) {
        notice = .changed(change)
    }

    func undo() async {
        guard let change else {
            return
        }

        notice = nil

        do {
            switch change.kind {
            case .recorded:
                try await database.deleteEntry(change.entry.id)
            case let .edited(previous):
                try await database.restoreEntry(previous)
            case .deleted:
                try await database.restoreEntry(change.entry)
            }

            notice = .undone
        } catch {
            notice = .undoFailed
        }
    }

    func clear() {
        notice = nil
    }
}

public extension EntryNoticeModel.Notice {
    var message: String {
        switch self {
        case let .changed(change): change.message
        case .undone: "取り消した"
        case .undoFailed: "取り消せませんでした"
        }
    }

    var seconds: Int {
        switch self {
        case .changed, .undoFailed: 4
        case .undone: 2
        }
    }
}
