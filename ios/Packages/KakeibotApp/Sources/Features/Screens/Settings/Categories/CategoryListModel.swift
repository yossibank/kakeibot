import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class CategoryListModel: ScreenModel {
    public var kind: EntryCategory.Kind = .expense

    public private(set) var list: CategoryList?
    public var movingOrder: [EntryCategory.ID]?

    public var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension CategoryListModel {
    var visible: [EntryCategory] {
        categories(isHidden: false)
    }

    var hidden: [EntryCategory] {
        categories(isHidden: true)
    }

    func icon(for category: EntryCategory) -> Icon? {
        list?.icons[category.iconId]
    }

    func load() async {
        do {
            list = try await database.categoryList()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observe() async {
        await observe(
            database.categoryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }
}

private extension CategoryListModel {
    static let loadFailedMessage = "カテゴリを読めませんでした"

    func categories(isHidden: Bool) -> [EntryCategory] {
        let categories = list?.categories ?? []

        return categories.filter { category in
            category.kind == kind && (category.archivedAt != nil) == isHidden
        }
    }
}

extension CategoryListModel: SettingsBoardModel {
    public func reload() async {
        await load()
    }

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
        try await database.deleteCategory(id)
    }

    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await database.restore(deletion)
    }

    public func isInUse(_ error: any Error) -> Bool {
        error as? AppDatabase.CategoryWriteError == .hasEntries
    }
}
