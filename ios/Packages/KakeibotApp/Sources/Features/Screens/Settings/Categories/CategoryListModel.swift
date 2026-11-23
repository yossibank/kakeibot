import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class CategoryListModel {
    public var kind: EntryCategory.Kind = .expense
    public var movingOrder: [EntryCategory.ID]?
    public var errorNotice = ErrorNotice()

    public internal(set) var snapshot: CategoryList?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension CategoryListModel {
    func icon(for category: EntryCategory) -> Icon? {
        snapshot?.icons[category.iconId]
    }
}

extension CategoryListModel: SettingsBoardListModel {
    typealias Item = EntryCategory

    static let loadFailedMessage = "カテゴリを読めませんでした"

    func read() async throws -> CategoryList {
        try await database.categoryList()
    }

    func updates() -> some AsyncSequence<CategoryList, any Error> {
        database.categoryListUpdates()
    }

    func items(in snapshot: CategoryList) -> [EntryCategory] {
        snapshot.categories.filter { $0.kind == kind }
    }

    func isHidden(_ item: EntryCategory) -> Bool {
        item.archivedAt != nil
    }
}

extension CategoryListModel: SettingsBoardModel {
    public func saveOrder(_ ids: [EntryCategory.ID]) async throws {
        let ids = ids + hidden.map(\.id)
        try await database.reorderCategories(ids, at: Date())
    }

    public func saveHidden(
        _ id: EntryCategory.ID,
        isHidden: Bool
    ) async throws {
        try await database.setCategoryHidden(
            id,
            isHidden: isHidden,
            at: Date()
        )
    }

    public func remove(_ id: EntryCategory.ID) async throws -> Deletion {
        try await database.deleteCategory(
            id,
            at: Date()
        )
    }

    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await database.restore(deletion)
    }

    public func isInUse(_ error: any Error) -> Bool {
        error as? AppDatabase.CategoryWriteError == .hasEntries
    }
}
