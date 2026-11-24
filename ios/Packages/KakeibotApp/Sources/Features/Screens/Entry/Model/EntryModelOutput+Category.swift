import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel.Output {
    var categories: [EntryCategory] {
        categories(for: state.type)
    }

    var templates: [EntryTemplate] {
        input.allTemplates.filter { $0.type == state.type }
    }

    var categoryPages: [[EntryModel.CategoryCell]] {
        let cells = categories.map(EntryModel.CategoryCell.category) + [.add, .edit]
        let size = EntryModel.categoriesPerPage

        return stride(from: 0, to: cells.count, by: size).map { start in
            Array(cells[start..<min(start + size, cells.count)])
        }
    }

    var selectedCategory: EntryCategory? {
        categories.first { $0.id == state.category.id }
    }

    var tags: [EntryTag] {
        let choice = state.category

        return allTags.filter { tag in
            tag.categoryId == choice.id
                && (tag.archivedAt == nil || tag.id == choice.tagId)
        }
    }

    var recentEntries: [Entry] {
        let type = state.type

        guard type != .transfer else {
            return []
        }

        let shown = Set(categories.map(\.id))

        let templateKeys = templates.map { template in
            Self.recentKey(
                categoryId: template.categoryId,
                amount: template.amount,
                memo: template.memo
            )
        }

        let editingId = input.editingId

        let entries = (input.history?.entries ?? [])
            .filter { entry in
                entry.type == type
                    && entry.recurringId == nil
                    && entry.transferId == nil
                    && entry.id != editingId
                    && entry.categoryId.map(shown.contains) == true
            }
            .sorted { $0.createdAt > $1.createdAt }

        var seen = Set(templateKeys)

        let unique = entries.filter { entry in
            let key = Self.recentKey(
                categoryId: entry.categoryId,
                amount: entry.amount,
                memo: entry.memo
            )

            return seen.insert(key).inserted
        }

        return Array(unique.prefix(EntryModel.recentEntryLimit))
    }

    func icon(for category: EntryCategory) -> Icon? {
        input.options?.icons[category.iconId]
    }

    func icon(for template: EntryTemplate) -> Icon? {
        category(of: template).flatMap(icon(for:))
    }

    func category(of template: EntryTemplate) -> EntryCategory? {
        allCategories.first { $0.id == template.categoryId }
    }

    func category(of entry: Entry) -> EntryCategory? {
        categories.first { $0.id == entry.categoryId }
    }

    func isApplied(_ template: EntryTemplate) -> Bool {
        let amountMatches = template.amount.map { $0 == amount } ?? true
        let memoMatches = EntryModel.filledMemo(of: template).map { $0 == state.memo } ?? true

        return template.id == state.appliedTemplateId
            && template.type == state.type
            && template.categoryId == state.category.id
            && recordableTagId(of: template) == state.category.tagId
            && template.walletId == state.payment.walletId
            && memoMatches
            && amountMatches
    }

    func recordableTagId(of template: EntryTemplate) -> EntryTag.ID? {
        allTags.first { $0.id == template.tagId && $0.archivedAt == nil }?.id
    }
}

extension EntryModel.Output {
    var allCategories: [EntryCategory] {
        let options = input.options
        let own = (options?.expenseCategories ?? []) + (options?.incomeCategories ?? [])
        return own + (options?.sharedCategories ?? [])
    }

    var allTags: [EntryTag] {
        (input.options?.tags ?? []) + (input.options?.sharedTags ?? [])
    }

    func categories(for type: Entry.Kind) -> [EntryCategory] {
        let categories = switch type {
        case .expense: offeredCategories(of: .expense)
        case .income: offeredCategories(of: .income)
        case .transfer: [EntryCategory]()
        }

        guard isEditing else {
            return categories
        }

        let ids = Set([state.category.id, state.category.byType[type]].compactMap(\.self))

        let kept = ids
            .compactMap { input.history?.categories[$0] }
            .filter { kept in
                kept.kind.rawValue == type.rawValue
                    && !categories.contains { $0.id == kept.id }
            }

        return (categories + kept).sorted { $0.sortOrder < $1.sortOrder }
    }
}

private extension EntryModel.Output {
    var walletCategories: [EntryCategory] {
        let categories = input.options?.sharedCategories ?? []
        let walletId = state.payment.walletId

        return categories.filter { category in
            category.walletId != nil && category.walletId == walletId
        }
    }

    static func recentKey(
        categoryId: EntryCategory.ID?,
        amount: Int?,
        memo: String?
    ) -> String {
        let category = categoryId.map { "\($0)" } ?? ""
        let amount = amount.map { "\($0)" } ?? ""
        return "\(category)>\(amount)>\(memo ?? "")"
    }

    func offeredCategories(of kind: EntryCategory.Kind) -> [EntryCategory] {
        let shared = walletCategories

        guard shared.isEmpty else {
            return shared.filter { $0.kind == kind }
        }

        return switch kind {
        case .expense: input.options?.expenseCategories ?? []
        case .income: input.options?.incomeCategories ?? []
        }
    }
}
