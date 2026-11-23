import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class StampListModel {
    public var movingOrder: [ShelfIcon.ID]?
    public var errorNotice = ErrorNotice()

    public internal(set) var snapshot: ShelfIconList?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension StampListModel {
    func icon(for shelfIcon: ShelfIcon) -> Icon? {
        snapshot?.icons[shelfIcon.iconId]
    }
}

extension StampListModel: SettingsBoardDatabaseModel {
    typealias Item = ShelfIcon

    static let loadFailedMessage = "スタンプを読めませんでした"

    func read() async throws -> ShelfIconList {
        try await database.shelfIconList()
    }

    func updates() -> some AsyncSequence<ShelfIconList, any Error> {
        database.shelfIconListUpdates()
    }

    func items(in snapshot: ShelfIconList) -> [ShelfIcon] {
        snapshot.shelfIcons
    }

    func isHidden(_ item: ShelfIcon) -> Bool {
        item.archivedAt != nil
    }
}

extension StampListModel: SettingsBoardModel {
    public func saveOrder(_ ids: [ShelfIcon.ID]) async throws {
        let ids = ids + hidden.map(\.id)
        try await database.reorder(ids, at: Date())
    }

    public func saveHidden(
        _ id: ShelfIcon.ID,
        isHidden: Bool
    ) async throws {
        try await database.setHidden(
            id,
            isHidden: isHidden,
            at: Date()
        )
    }

    public func remove(_ id: ShelfIcon.ID) async throws -> Deletion {
        try await database.deleteShelfIcon(id)
    }

    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await database.restore(deletion)
    }
}
