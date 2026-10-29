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
        let tags = options?.tags ?? []

        return tags.filter { tag in
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

        return template.id == appliedTemplateId
            && template.type == type
            && template.categoryId == categoryId
            && recordableTagId(of: template) == tagId
            && template.walletId == walletId
            && (template.memo ?? "") == memo
            && amountMatches
    }

    func recordableTagId(of template: EntryTemplate) -> EntryTag.ID? {
        let tags = options?.tags ?? []

        return tags.first { $0.id == template.tagId && $0.archivedAt == nil }?.id
    }

    func apply(_ template: EntryTemplate) {
        select(template.type)

        categoryId = template.categoryId
        tagId = recordableTagId(of: template)
        walletId = template.walletId
        memo = template.memo ?? ""
        calculator = AmountCalculator(amount: template.amount ?? 0)
        appliedTemplateId = template.id
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
            errorNotice.show(Self.restoreFailedMessage)
        }
    }

    func hideCategory(_ category: EntryCategory) async {
        do {
            try await database.setCategoryHidden(
                category.id,
                isHidden: true,
                at: Date()
            )

            await reloadCategories()
        } catch {
            report(error)
        }
    }
}

extension EntryModel {
    func categories(for type: Entry.Kind) -> [EntryCategory] {
        let categories = switch type {
        case .expense: options?.expenseCategories ?? []
        case .income: options?.incomeCategories ?? []
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
}

private extension EntryModel {
    static let restoreFailedMessage = "元に戻せませんでした"
}
