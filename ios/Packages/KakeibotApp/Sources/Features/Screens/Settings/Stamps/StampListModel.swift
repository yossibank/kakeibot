import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class StampListModel: ScreenModel {
    public private(set) var shelf: IconShelf?
    public var movingOrder: [ShelfIcon.ID]?

    public var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension StampListModel {
    var visible: [ShelfIcon] {
        stamps(isHidden: false)
    }

    var hidden: [ShelfIcon] {
        stamps(isHidden: true)
    }

    func icon(for shelfIcon: ShelfIcon) -> Icon? {
        shelf?.icons[shelfIcon.iconId]
    }

    func load() async {
        do {
            shelf = try await database.iconShelf()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observe() async {
        await observe(
            database.iconShelfUpdates(),
            failure: Self.loadFailedMessage
        ) { shelf in
            self.shelf = shelf
        }
    }
}

private extension StampListModel {
    static let loadFailedMessage = "スタンプを読めませんでした"

    func stamps(isHidden: Bool) -> [ShelfIcon] {
        let stamps = shelf?.shelfIcons ?? []
        return stamps.filter { ($0.archivedAt != nil) == isHidden }
    }
}

extension StampListModel: SettingsBoardModel {
    public func reload() async {
        await load()
    }

    public func saveOrder(_ ids: [ShelfIcon.ID]) async throws {
        let ids = ids + hidden.map(\.id)
        try await database.reorderShelfIcons(ids, at: Date())
    }

    public func saveHidden(
        _ id: ShelfIcon.ID,
        isHidden: Bool
    ) async throws {
        try await database.setShelfIconHidden(
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
