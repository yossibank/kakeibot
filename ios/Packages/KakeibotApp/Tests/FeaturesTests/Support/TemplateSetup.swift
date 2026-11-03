import Core
import Foundation
import Store
import Testing

struct TemplateSetup {
    let database: AppDatabase
    let date: LocalDate
}

extension TemplateSetup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let date = try #require(LocalDate("2026-10-15"))

        try database.insertDefaultsIfEmpty(at: Date())
        self.init(database: database, date: date)
    }

    func saveTag(_ name: String) async throws -> EntryTag {
        let list = try await database.categoryList()
        let options = try await database.entryOptions()
        let category = options.expenseCategories[1]
        let icon = try #require(list.icons[category.iconId])
        let draft = EntryCategoryDraft(category, icon: icon)
        let tagDrafts = [EntryTagDraft(name: name)]

        try await database.saveCategory(draft, tags: tagDrafts, editing: category.id, at: Date())

        let tags = try await database.categoryList().tags

        return try #require(tags.first)
    }

    @discardableResult
    func saveTemplate(
        name: String,
        amount: Int?,
        type: Entry.Kind = .expense,
        tagId: EntryTag.ID? = nil,
        memo: String = "社食"
    ) async throws -> EntryTemplate {
        let options = try await database.entryOptions()
        let categories = type == .income ? options.incomeCategories : options.expenseCategories

        let draft = EntryTemplateDraft(
            name: name,
            type: type,
            amount: amount,
            categoryId: categories[1].id,
            tagId: tagId,
            walletId: options.wallets[0].id,
            memo: memo
        )

        return try await database.saveTemplate(draft, at: Date())
    }
}
