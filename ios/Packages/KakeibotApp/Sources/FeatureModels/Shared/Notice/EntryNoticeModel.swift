import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class EntryNoticeModel {
    public let state: State
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock
    ) {
        let state = State()

        self.state = state
        self.output = Output(state: state)
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension EntryNoticeModel {
    enum Notice: Hashable, Sendable {
        case changed(EntryChange)
        case batch(EntryBatch)
        case undone
        case failed(String)
    }

    @MainActor
    @Observable
    final class State {
        public private(set) var notice: Notice?

        func show(_ notice: Notice) {
            self.notice = notice
        }

        func clear() {
            notice = nil
        }
    }

    @MainActor
    final class Output {
        let state: State

        public var change: EntryChange? {
            if case let .changed(change) = state.notice {
                change
            } else {
                nil
            }
        }

        init(state: State) {
            self.state = state
        }
    }

    func show(_ change: EntryChange) {
        state.show(.changed(change))
    }

    func undo() async {
        let undone = state.notice

        state.clear()

        do {
            switch undone {
            case let .changed(change):
                try await undo(change)

            case let .batch(batch):
                let items = batch.kind == .deleted ? batch.items : nil
                try await dependencies.database.restoreEntries(
                    batch.previous,
                    items: items,
                    at: dependencies.clock.now
                )

            case .undone, .failed, nil:
                return
            }

            state.show(.undone)
        } catch {
            state.show(.failed(Self.undoFailedMessage))
        }
    }

    func changeEntries(
        _ ids: [Entry.ID],
        to change: EntryBatchChange
    ) async {
        let kind: EntryBatch.Kind = switch change {
        case .category: .changedCategory
        case .wallet: .changedWallet
        }

        do {
            let previous = try await dependencies.database.changeEntries(
                ids,
                to: change,
                at: dependencies.clock.now
            )

            let batch = EntryBatch(kind: kind, previous: previous)

            state.show(.batch(batch))
        } catch {
            state.show(.failed(Self.changeFailedMessage(of: kind)))
        }
    }

    func deleteEntries(_ ids: [Entry.ID]) async {
        do {
            let items = try await dependencies.database.entryItems(of: ids)
            let previous = try await dependencies.database.deleteEntries(
                ids,
                at: dependencies.clock.now
            )
            let batch = EntryBatch(kind: .deleted, previous: previous, items: items)
            state.show(.batch(batch))
        } catch {
            state.show(.failed(Self.deleteFailedMessage))
        }
    }

    func delete(
        _ id: Entry.ID,
        in list: EntryList?
    ) async {
        let entries = list?.entries ?? []

        guard
            let list,
            let entry = entries.first(where: { $0.id == id })
        else {
            return
        }

        do {
            let items = try await dependencies.database.entryItems(of: id)
            let deleted = try await dependencies.database.deleteEntry(
                id,
                at: dependencies.clock.now
            )

            let label = EntryChange.label(for: entry) { id in
                list.categories[id]
            } wallet: { id in
                list.wallets[id]
            }

            let fee = deleted.first { $0.transferId == id }

            let change = EntryChange(
                kind: .deleted,
                entry: deleted.first { $0.id == id } ?? entry,
                label: label,
                fee: fee,
                items: items
            )

            show(change)
        } catch {
            state.show(.failed(Self.deleteFailedMessage))
        }
    }

    func clear() {
        state.clear()
    }

    func clearOnTap() {
        guard state.notice?.dismissesOnTap == true else {
            return
        }

        state.clear()
    }
}

public extension EntryNoticeModel.Notice {
    static let batchSeconds = 8

    var message: String {
        switch self {
        case let .changed(change): change.message
        case let .batch(batch): batch.message
        case .undone: "取り消しました"
        case let .failed(message): message
        }
    }

    var seconds: Int {
        switch self {
        case .changed, .failed: 4
        case .batch: Self.batchSeconds
        case .undone: 2
        }
    }

    var dismissesOnTap: Bool {
        switch self {
        case let .changed(change): !change.isDeletion
        case .batch: false
        case .undone, .failed: true
        }
    }
}

extension EntryNoticeModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }
}

private extension EntryNoticeModel {
    static let undoFailedMessage = "取り消せませんでした"
    static let deleteFailedMessage = "削除できませんでした"

    static func changeFailedMessage(of kind: EntryBatch.Kind) -> String {
        switch kind {
        case .changedCategory: "カテゴリを変えられませんでした"
        case .changedWallet: "口座を変えられませんでした"
        case .deleted: deleteFailedMessage
        }
    }

    func undo(_ change: EntryChange) async throws {
        switch change.kind {
        case .recorded:
            try await dependencies.database.deleteEntry(
                change.entry.id,
                restoringNoSpend: change.clearedNoSpendDays,
                at: dependencies.clock.now
            )

        case let .edited(previous, previousFee):
            try await dependencies.database.restoreEntry(
                previous,
                fee: previousFee,
                restoringNoSpend: change.clearedNoSpendDays,
                at: dependencies.clock.now
            )

        case .deleted:
            try await dependencies.database.restoreEntry(
                change.entry,
                fee: change.fee,
                items: change.items,
                at: dependencies.clock.now
            )
        }
    }
}
