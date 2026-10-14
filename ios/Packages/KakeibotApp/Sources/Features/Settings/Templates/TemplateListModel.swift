import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class TemplateListModel {
    public private(set) var templates: [EntryTemplate] = []
    public private(set) var categories: CategoryList?
    public private(set) var wallets: [Wallet] = []
    public private(set) var errorMessage: String?

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension TemplateListModel {
    func icon(for template: EntryTemplate) -> Icon? {
        let category = category(for: template)
        return category.flatMap { categories?.icons[$0.iconId] }
    }

    func detail(for template: EntryTemplate) -> String {
        let type = template.type == .income ? "収入" : "支出"
        let category = category(for: template)?.name
        let wallet = wallets.first { $0.id == template.walletId }?.name
        let parts = [type, category, wallet, template.memo]
        return parts.compactMap(\.self).joined(separator: "・")
    }

    func amountText(for template: EntryTemplate) -> String {
        template.amount.map { AmountText.text($0) } ?? "毎回入れる"
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
        from source: IndexSet,
        to destination: Int
    ) async {
        var reordered = templates
        reordered.move(fromOffsets: source, toOffset: destination)
        templates = reordered

        do {
            let ids = reordered.map(\.id)
            try await database.reorderTemplates(ids, at: Date())
        } catch {
            errorMessage = Self.saveFailedMessage
        }
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
