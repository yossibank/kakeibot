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
        case failed(String)
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
            notice = .failed(Self.undoFailedMessage)
        }
    }

    func delete(
        _ id: Entry.ID,
        in list: EntryList?
    ) async {
        let entries = list?.days.flatMap(\.entries) ?? []

        guard let list, let entry = entries.first(where: { $0.id == id }) else {
            return
        }

        do {
            try await database.deleteEntry(id)

            let label = EntryChange.label(for: entry) { id in
                list.categories[id]
            } wallet: { id in
                list.wallets[id]
            }

            let change = EntryChange(kind: .deleted, entry: entry, label: label)
            show(change)
        } catch {
            notice = .failed(Self.deleteFailedMessage)
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
        case let .failed(message): message
        }
    }

    var seconds: Int {
        switch self {
        case .changed, .failed: 4
        case .undone: 2
        }
    }
}

private extension EntryNoticeModel {
    static let undoFailedMessage = "取り消せませんでした"
    static let deleteFailedMessage = "削除できませんでした"
}
