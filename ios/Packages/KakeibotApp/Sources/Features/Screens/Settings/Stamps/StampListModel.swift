import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class StampListModel {
    public let state: SettingsBoardMovingState<ShelfIcon.ID>
    public let input: SettingsBoardSnapshotInput<ShelfIconList>
    public let output: Output

    let dependencies: SettingsBoardDependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock
    ) {
        let state = SettingsBoardMovingState<ShelfIcon.ID>()
        let input = SettingsBoardSnapshotInput<ShelfIconList>()

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = SettingsBoardDependencies(database: database, clock: clock)
    }
}

public extension StampListModel {
    @MainActor
    final class Output: SettingsBoardOutput {
        let input: SettingsBoardSnapshotInput<ShelfIconList>
        let state: SettingsBoardMovingState<ShelfIcon.ID>

        var items: [ShelfIcon] {
            input.snapshot?.shelfIcons ?? []
        }

        init(
            input: SettingsBoardSnapshotInput<ShelfIconList>,
            state: SettingsBoardMovingState<ShelfIcon.ID>
        ) {
            self.input = input
            self.state = state
        }

        public func icon(for shelfIcon: ShelfIcon) -> Icon? {
            input.snapshot?.icons[shelfIcon.iconId]
        }
    }
}

extension StampListModel: SettingsBoardDatabaseModel {
    typealias Item = ShelfIcon

    static let loadFailedMessage = "スタンプを読めませんでした"

    func read() async throws -> ShelfIconList {
        try await dependencies.database.shelfIconList()
    }

    func updates() -> some AsyncSequence<ShelfIconList, any Error> {
        dependencies.database.shelfIconListUpdates()
    }
}

extension StampListModel: SettingsBoardModel {
    public func remove(_ id: ShelfIcon.ID) async throws -> Deletion {
        try await dependencies.database.deleteShelfIcon(id)
    }
}
