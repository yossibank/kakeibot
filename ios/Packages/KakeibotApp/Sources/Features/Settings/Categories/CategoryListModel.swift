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
    public private(set) var movingOrder: [EntryCategory.ID]?

    public internal(set) var errorNotice = ErrorNotice()

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

    func move(
        _ id: EntryCategory.ID,
        to index: Int
    ) {
        var order = movingOrder ?? shown.map(\.id)

        guard let from = order.firstIndex(of: id) else {
            return
        }

        let to = min(max(index, 0), order.count - 1)

        guard from != to else {
            return
        }

        order.remove(at: from)
        order.insert(id, at: to)
        movingOrder = order
    }

    func cancelMoving() {
        movingOrder = nil
    }

    @discardableResult
    func hide(_ id: EntryCategory.ID) async -> Bool {
        movingOrder = nil

        do {
            try await database.setCategoryHidden(
                id,
                isHidden: true,
                at: Date()
            )

            await load()
            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return false
        }
    }

    func show(_ id: EntryCategory.ID) async {
        do {
            try await database.setCategoryHidden(
                id,
                isHidden: false,
                at: Date()
            )

            await load()
        } catch {
            errorNotice.show(Self.showFailedMessage)
        }
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
            errorNotice.show(Self.saveFailedMessage)
        }

        self.movingOrder = nil
    }
}

private extension CategoryListModel {
    static let loadFailedMessage = "カテゴリを読めませんでした"
    static let saveFailedMessage = "並びを保存できませんでした"
    static let showFailedMessage = "表示に戻せませんでした"

    func categories(isHidden: Bool) -> [EntryCategory] {
        let categories = list?.categories ?? []

        return categories.filter { category in
            category.kind == kind && (category.archivedAt != nil) == isHidden
        }
    }
}
