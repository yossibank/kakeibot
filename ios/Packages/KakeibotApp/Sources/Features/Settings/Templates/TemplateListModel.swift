import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class TemplateListModel {
    public var type: Entry.Kind = .expense

    public private(set) var templates: [EntryTemplate] = []
    public private(set) var movingOrder: [EntryTemplate.ID]?
    public private(set) var categories: CategoryList?
    public private(set) var wallets: [Wallet] = []
    public private(set) var errorMessage: String?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension TemplateListModel {
    var shown: [EntryTemplate] {
        let templates = templates.filter { $0.type == type }

        guard let movingOrder else {
            return templates
        }

        return movingOrder.compactMap { id in
            templates.first { $0.id == id }
        }
    }

    func icon(for template: EntryTemplate) -> Icon? {
        let category = category(for: template)
        return category.flatMap { categories?.icons[$0.iconId] }
    }

    func detail(for template: EntryTemplate) -> String {
        let category = category(for: template)?.name
        let wallet = wallets.first { $0.id == template.walletId }?.name
        let parts = [category, wallet]
        return parts.compactMap(\.self).joined(separator: "・")
    }

    func load() async {
        do {
            templates = try await database.templates()
            try await loadNames()
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func observe() async {
        do {
            try await loadNames()

            for try await templates in database.templateUpdates() {
                self.templates = templates
                try await loadNames()
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    func move(
        _ id: EntryTemplate.ID,
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

    func finishMoving() async {
        guard let movingOrder else {
            return
        }

        let others = templates.filter { $0.type != type }.map(\.id)
        let ids = movingOrder + others

        do {
            try await database.reorderTemplates(ids, at: Date())
            templates = try await database.templates()
        } catch {
            errorMessage = Self.saveFailedMessage
        }

        self.movingOrder = nil
    }
}

private extension TemplateListModel {
    static let loadFailedMessage = "テンプレートを読めませんでした"
    static let saveFailedMessage = "並びを保存できませんでした"

    func category(for template: EntryTemplate) -> EntryCategory? {
        categories?.categories.first { $0.id == template.categoryId }
    }

    func loadNames() async throws {
        categories = try await database.categoryList()
        wallets = try await database.entryOptions().wallets
    }
}
