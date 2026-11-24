import Core
import DesignSystem
import Store

@MainActor
public protocol SettingsBoardListModel: SettingsBoardModel, ScreenModel {
    associatedtype Snapshot
    associatedtype Input: SettingsBoardInput where Input.Snapshot == Snapshot
    associatedtype Updates: AsyncSequence where Updates.Element == Snapshot

    var input: Input { get }
    var dependencies: ScreenParts { get }

    func read() async throws -> Snapshot
    func updates() -> Updates
    func observe() async
}

extension SettingsBoardListModel {
    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await dependencies.database.restore(deletion)
    }

    func load(into snapshot: ReferenceWritableKeyPath<Self, Snapshot?>) async {
        do {
            self[keyPath: snapshot] = try await read()
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }
}

public extension SettingsBoardListModel where Input == SettingsBoardSnapshotInput<Snapshot> {
    func load() async {
        await load(into: \.input.snapshot)
    }

    func observe() async {
        await observe(updates(), into: \.input.snapshot)
    }
}

public extension SettingsBoardListModel where Item: SortableRecord, Item.ID == Identifier<Item> {
    func saveOrder(_ ids: [Item.ID]) async throws {
        let ids = ids + output.hidden.map(\.id)
        try await dependencies.database.reorder(ids, at: dependencies.clock.now)
    }
}

public extension SettingsBoardListModel where Item: HidableRecord, Item.ID == Identifier<Item> {
    func saveHidden(
        _ id: Item.ID,
        isHidden: Bool
    ) async throws {
        try await dependencies.database.setHidden(
            id,
            isHidden: isHidden,
            at: dependencies.clock.now
        )
    }
}
