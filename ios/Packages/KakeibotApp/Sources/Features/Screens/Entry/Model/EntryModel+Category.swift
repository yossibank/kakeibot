import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel {
    enum CategoryCell: Hashable {
        case category(EntryCategory)
        case add
        case edit

        public var categoryId: EntryCategory.ID? {
            if case let .category(category) = self {
                category.id
            } else {
                nil
            }
        }
    }

    struct HiddenCategory: Hashable, Sendable {
        public let id: EntryCategory.ID
        public let wasSelected: Bool
    }

    static let categoriesPerPage = 15

    var categories: [EntryCategory] {
        categories(for: type)
    }

    var templates: [EntryTemplate] {
        allTemplates.filter { $0.type == type }
    }

    var categoryPages: [[CategoryCell]] {
        let cells = categories.map(CategoryCell.category) + [.add, .edit]
        let size = Self.categoriesPerPage

        return stride(from: 0, to: cells.count, by: size).map { start in
            Array(cells[start..<min(start + size, cells.count)])
        }
    }

    var selectedCategory: EntryCategory? {
        categories.first { $0.id == categoryId }
    }

    var tags: [EntryTag] {
        allTags.filter { tag in
            tag.categoryId == categoryId
                && (tag.archivedAt == nil || tag.id == tagId)
        }
    }

    func icon(for category: EntryCategory) -> Icon? {
        options?.icons[category.iconId]
    }

    func icon(for template: EntryTemplate) -> Icon? {
        let categories = categories(for: template.type)
        let category = categories.first { $0.id == template.categoryId }
        return category.flatMap { options?.icons[$0.iconId] }
    }

    func isApplied(_ template: EntryTemplate) -> Bool {
        let amountMatches = template.amount.map { $0 == amount } ?? true
        let memoMatches = template.filledMemo.map { $0 == memo } ?? true

        return template.id == appliedTemplateId
            && template.type == type
            && template.categoryId == categoryId
            && recordableTagId(of: template) == tagId
            && template.walletId == walletId
            && memoMatches
            && amountMatches
    }

    func recordableTagId(of template: EntryTemplate) -> EntryTag.ID? {
        allTags.first { $0.id == template.tagId && $0.archivedAt == nil }?.id
    }

    func apply(_ template: EntryTemplate) {
        select(template.type)

        categoryId = template.categoryId
        tagId = recordableTagId(of: template)
        walletId = template.walletId
        appliedTemplateId = template.id
        billMonth = billRecurring?.billMonth(for: date, shift: template.billShift)

        if let memo = template.filledMemo {
            self.memo = memo
        }

        if let amount = template.amount {
            calculator = AmountCalculator(amount: amount)
        }
    }

    func toggleTag(_ id: EntryTag.ID) {
        tagId = tagId == id ? nil : id
    }

    func reloadTemplates() async {
        do {
            allTemplates = try await database.templates()
        } catch {
            report(error)
        }
    }

    func reloadCategories(selecting id: EntryCategory.ID? = nil) async {
        do {
            options = try await database.entryOptions()
            history = try await database.entryList()

            if let id {
                categoryId = id
            } else if !categories.contains(where: { $0.id == categoryId }) {
                categoryId = categories.first?.id
            }
        } catch {
            report(error)
        }
    }

    func newTemplateModel() -> TemplateEditModel {
        let templateType: Entry.Kind = type == .income ? .income : .expense

        let draft = EntryTemplateDraft(
            name: "",
            type: templateType,
            amount: amount > 0 ? amount : nil,
            categoryId: categoryId,
            tagId: tagId,
            walletId: walletId,
            memo: memo
        )

        return TemplateEditModel(database: database, draft: draft)
    }

    func newCategoryModel() -> CategoryEditModel {
        let kind: EntryCategory.Kind = type == .income ? .income : .expense
        return CategoryEditModel(database: database, kind: kind)
    }

    func editCategoryModel(_ category: EntryCategory) -> CategoryEditModel {
        CategoryEditModel(
            database: database,
            kind: category.kind,
            editing: category.id
        )
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await database.restore(deletion)
            await reloadCategories()
            await reloadTemplates()
        } catch {
            errorNotice.show(Self.restoreFailedMessage, for: error)
        }
    }

    func hideCategory(_ category: EntryCategory) async -> HiddenCategory? {
        let hidden = HiddenCategory(
            id: category.id,
            wasSelected: category.id == categoryId
        )

        do {
            try await database.setCategoryHidden(
                category.id,
                isHidden: true,
                at: Date()
            )

            await reloadCategories()

            return hidden
        } catch {
            report(error)
            return nil
        }
    }

    func showCategory(_ hidden: HiddenCategory) async {
        do {
            try await database.setCategoryHidden(
                hidden.id,
                isHidden: false,
                at: Date()
            )

            await reloadCategories(selecting: hidden.wasSelected ? hidden.id : nil)
        } catch {
            errorNotice.show(Self.restoreFailedMessage, for: error)
        }
    }
}

extension EntryModel {
    func categories(for type: Entry.Kind) -> [EntryCategory] {
        let categories = switch type {
        case .expense: offeredCategories(of: .expense)
        case .income: offeredCategories(of: .income)
        case .transfer: [EntryCategory]()
        }

        guard isEditing else {
            return categories
        }

        let ids = Set([categoryId, categoryByType[type]].compactMap(\.self))

        let kept = ids
            .compactMap { history?.categories[$0] }
            .filter { kept in
                kept.kind.rawValue == type.rawValue
                    && !categories.contains { $0.id == kept.id }
            }

        return (categories + kept).sorted { $0.sortOrder < $1.sortOrder }
    }

    func fitCategoryToWallet() {
        guard
            let categoryId,
            let current = allCategories.first(where: { $0.id == categoryId }),
            !categories.contains(where: { $0.id == categoryId })
        else {
            return
        }

        let tagName = allTags.first { $0.id == tagId }?.name
        let fitted = categories.first { $0.name == current.name } ?? categories.first

        self.categoryId = fitted?.id
        tagId = tags.first { $0.name == tagName }?.id
    }
}

private extension EntryModel {
    static let restoreFailedMessage = "元に戻せませんでした"

    var allCategories: [EntryCategory] {
        let own = (options?.expenseCategories ?? []) + (options?.incomeCategories ?? [])
        return own + (options?.sharedCategories ?? [])
    }

    var allTags: [EntryTag] {
        (options?.tags ?? []) + (options?.sharedTags ?? [])
    }

    var walletCategories: [EntryCategory] {
        let categories = options?.sharedCategories ?? []

        return categories.filter { category in
            category.walletId != nil && category.walletId == walletId
        }
    }

    func offeredCategories(of kind: EntryCategory.Kind) -> [EntryCategory] {
        let shared = walletCategories

        guard shared.isEmpty else {
            return shared.filter { $0.kind == kind }
        }

        return switch kind {
        case .expense: options?.expenseCategories ?? []
        case .income: options?.incomeCategories ?? []
        }
    }
}

private extension EntryTemplate {
    var filledMemo: String? {
        memo.flatMap { $0.isEmpty ? nil : $0 }
    }
}
