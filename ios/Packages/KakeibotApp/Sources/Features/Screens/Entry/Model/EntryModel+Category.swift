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

    func apply(_ template: EntryTemplate) {
        select(template.type)

        state.setCategory(template.categoryId)
        state.category.tagId = output.recordableTagId(of: template)
        setWallet(template.walletId)
        state.appliedTemplateId = template.id

        state.payment.billMonth = output.billRecurring?.billMonth(
            for: state.payment.date,
            shift: template.billShift
        )

        if let memo = Self.filledMemo(of: template) {
            state.memo = memo
        }

        if let amount = template.amount {
            state.keypad.setAmount(amount)
        }
    }

    func reloadTemplates() async {
        do {
            input.allTemplates = try await dependencies.database.templates()
        } catch {
            report(error)
        }
    }

    func reloadCategories(selecting id: EntryCategory.ID? = nil) async {
        do {
            input.options = try await dependencies.database.entryOptions()
            input.history = try await dependencies.database.entryList()

            if let id {
                state.setCategory(id)
            } else if !output.categories.contains(where: { $0.id == state.category.id }) {
                state.setCategory(output.categories.first?.id)
            }
        } catch {
            report(error)
        }
    }

    func newTemplateModel() -> TemplateEditModel {
        let templateType: Entry.Kind = state.type == .income ? .income : .expense
        let amount = output.amount

        let draft = EntryTemplateDraft(
            name: "",
            type: templateType,
            amount: amount > 0 ? amount : nil,
            categoryId: state.category.id,
            tagId: state.category.tagId,
            walletId: state.payment.walletId,
            memo: state.memo
        )

        return TemplateEditModel(
            database: dependencies.database,
            clock: dependencies.clock,
            draft: draft
        )
    }

    func newCategoryModel() -> CategoryEditModel {
        let kind: EntryCategory.Kind = state.type == .income ? .income : .expense

        return CategoryEditModel(
            database: dependencies.database,
            clock: dependencies.clock,
            kind: kind
        )
    }

    func editCategoryModel(_ category: EntryCategory) -> CategoryEditModel {
        CategoryEditModel(
            database: dependencies.database,
            clock: dependencies.clock,
            kind: category.kind,
            editing: category.id
        )
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await dependencies.database.restore(deletion)
            await reloadCategories()
            await reloadTemplates()
        } catch {
            state.errorNotice.show(Self.restoreFailedMessage, for: error)
        }
    }

    func hideCategory(_ category: EntryCategory) async -> HiddenCategory? {
        let hidden = HiddenCategory(
            id: category.id,
            wasSelected: category.id == state.category.id
        )

        do {
            try await dependencies.database.setHidden(
                category.id,
                isHidden: true,
                at: dependencies.clock.now
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
            try await dependencies.database.setHidden(
                hidden.id,
                isHidden: false,
                at: dependencies.clock.now
            )

            await reloadCategories(selecting: hidden.wasSelected ? hidden.id : nil)
        } catch {
            state.errorNotice.show(Self.restoreFailedMessage, for: error)
        }
    }
}

extension EntryModel {
    static func filledMemo(of template: EntryTemplate) -> String? {
        template.memo.flatMap { $0.isEmpty ? nil : $0 }
    }

    func childParts() -> ScreenParts {
        ScreenParts(database: dependencies.database, clock: dependencies.clock)
    }
}

private extension EntryModel {
    static let restoreFailedMessage = "元に戻せませんでした"
}
