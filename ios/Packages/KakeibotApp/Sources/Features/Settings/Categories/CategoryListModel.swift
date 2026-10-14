import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class CategoryListModel {
    public var kind: EntryCategory.Kind = .expense

    public private(set) var list: CategoryList?
    public private(set) var movingOrder: [EntryCategory.ID]?
    public private(set) var errorMessage: String?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension CategoryListModel {
    var shown: [EntryCategory] {
        let categories = categories(isHidden: false)

        guard let movingOrder else {
            return categories
        }

        return movingOrder.compactMap { id in
            categories.first { $0.id == id }
        }
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
            errorMessage = Self.loadFailedMessage
        }
    }

    func observe() async {
        do {
            for try await list in database.categoryListUpdates() {
                self.list = list
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func move(
        _ id: EntryCategory.ID,
        to target: EntryCategory.ID
    ) {
        var order = movingOrder ?? shown.map(\.id)

        guard
            id != target,
            let from = order.firstIndex(of: id),
            let to = order.firstIndex(of: target) else {
            return
        }

        order.remove(at: from)
        order.insert(id, at: to)
        movingOrder = order
    }

    func finishMoving() async {
        guard let movingOrder else {
            return
        }

        let ids = movingOrder + hidden.map(\.id)

        do {
            try await database.reorderCategories(ids, at: Date())
            await load()
        } catch {
            errorMessage = Self.saveFailedMessage
        }

        self.movingOrder = nil
    }
}

private extension CategoryListModel {
    static let loadFailedMessage = "カテゴリを読めませんでした"
    static let saveFailedMessage = "並びを保存できませんでした"

    func categories(isHidden: Bool) -> [EntryCategory] {
        let categories = list?.categories ?? []

        return categories.filter { category in
            category.kind == kind && (category.archivedAt != nil) == isHidden
        }
    }
}
