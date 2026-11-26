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
    public let dependencies: ScreenParts

    public init(parts: ScreenParts) {
        let state = SettingsBoardMovingState<ShelfIcon.ID>()
        let input = SettingsBoardSnapshotInput<ShelfIconList>(screen: .stamps)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = parts
    }
}

public extension StampListModel {
    @MainActor
    final class Output: SettingsBoardOutput {
        public let state: SettingsBoardMovingState<ShelfIcon.ID>

        let input: SettingsBoardSnapshotInput<ShelfIconList>

        init(
            input: SettingsBoardSnapshotInput<ShelfIconList>,
            state: SettingsBoardMovingState<ShelfIcon.ID>
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension StampListModel.Output {
    var items: [ShelfIcon] {
        input.snapshot?.shelfIcons ?? []
    }

    func icon(for shelfIcon: ShelfIcon) -> Icon? {
        input.snapshot?.icons[shelfIcon.iconId]
    }
}

extension StampListModel: SettingsBoardDatabaseModel {
    public typealias Item = ShelfIcon

    public static let loadFailedMessage = "スタンプを読めませんでした"

    public func read() async throws -> ShelfIconList {
        try await dependencies.database.shelfIconList()
    }

    public func updates() -> some AsyncSequence<ShelfIconList, any Error> {
        dependencies.database.shelfIconListUpdates()
    }
}

extension StampListModel: SettingsBoardModel {
    public func remove(_ id: ShelfIcon.ID) async throws -> Deletion {
        try await dependencies.database.deleteShelfIcon(id)
    }
}
