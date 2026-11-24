import Core
import DesignSystem
import Store

@MainActor
protocol SettingsBoardListModel: SettingsBoardModel, ScreenModel {
    associatedtype Input: SettingsBoardInput
    associatedtype Updates: AsyncSequence where Updates.Element == Input.Snapshot

    var input: Input { get }
    var dependencies: SettingsBoardDependencies { get }

    func read() async throws -> Input.Snapshot
    func updates() -> Updates
    func observe() async
}

extension SettingsBoardListModel {
    var errorNotice: ErrorNotice {
        get {
            state.errorNotice
        }
        set {
            state.errorNotice = newValue
        }
    }

    func load() async {
        do {
            input.snapshot = try await read()
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observe() async {
        await observe(updates(), into: \.input.snapshot)
    }

    func restoreRemoved(_ deletion: Deletion) async throws {
        try await dependencies.database.restore(deletion)
    }
}

extension SettingsBoardListModel where Item: SortableRecord, Item.ID == Identifier<Item> {
    func saveOrder(_ ids: [Item.ID]) async throws {
        let ids = ids + output.hidden.map(\.id)
        try await dependencies.database.reorder(ids, at: dependencies.clock.now)
    }
}

extension SettingsBoardListModel where Item: HidableRecord, Item.ID == Identifier<Item> {
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
