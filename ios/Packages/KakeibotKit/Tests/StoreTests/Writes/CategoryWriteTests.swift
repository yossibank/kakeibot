import Core
import Foundation
import Store
import Testing

struct CategoryWriteTests {
    @Test
    func addsCategoryAfterSameKind() async throws {
        let setup = try await Setup()

        let saved = try await setup.database.saveCategory(
            setup.draft,
            tags: [],
            at: setup.now
        )
        let list = try await setup.database.categoryList()
        let icon = try #require(list.icons[saved.iconId])

        #expect(saved.sortOrder == 12)
        #expect(saved.name == "外食")
        #expect(icon.glyph == .cafe)
        #expect(icon.color == "#E07A5F")
        #expect(list.categories.contains(saved))
    }

    @Test
    func updatesNameAndIcon() async throws {
        let setup = try await Setup()
        let later = setup.now.addingTimeInterval(60)
        let food = try await setup.category(named: "食費")
        var draft = setup.draft
        draft.name = "ごはん"
        draft.mark = .emoji("🍙")

        let updated = try await setup.database.saveCategory(
            draft,
            tags: [],
            editing: food.id,
            at: later
        )
        let list = try await setup.database.categoryList()
        let icon = try #require(list.icons[updated.iconId])

        #expect(updated.id == food.id)
        #expect(updated.name == "ごはん")
        #expect(updated.sortOrder == food.sortOrder)
        #expect(updated.updatedAt == later)
        #expect(icon.id == food.iconId)
        #expect(icon.emoji == "🍙")
        #expect(icon.glyph == nil)
    }

    @Test
    func rejectsUnknownCategory() async throws {
        let setup = try await Setup()

        await #expect(throws: AppDatabase.CategoryWriteError.categoryNotFound) {
            try await setup.database.saveCategory(
                setup.draft,
                tags: [],
                editing: EntryCategory.ID(),
                at: setup.now
            )
        }
    }

    @Test
    func reordersCategories() async throws {
        let setup = try await Setup()
        let before = try await setup.expenseCategories()
        let reversed = before.map(\.id).reversed()

        try await setup.database.reorderCategories(
            Array(reversed),
            at: setup.now
        )
        let after = try await setup.expenseCategories()

        #expect(after.map(\.id) == Array(reversed))
        #expect(after.map(\.sortOrder) == Array(0..<before.count))
    }

    @Test
    func deletesUnusedCategory() async throws {
        let setup = try await Setup()
        let food = try await setup.category(named: "食費")

        let deletion = try await setup.database.deleteCategory(food.id)
        let categories = try await setup.expenseCategories()

        try await setup.database.restore(deletion)
        let restored = try await setup.category(named: "食費")

        #expect(!categories.contains { $0.id == food.id })
        #expect(restored == food)
    }

    @Test
    func keepsCategoryWithEntries() async throws {
        let setup = try await Setup()
        let food = try await setup.category(named: "食費")
        let options = try await setup.database.entryOptions()
        let wallet = try #require(options.wallets.first)
        let day = try #require(LocalDate("2026-11-01"))

        let entry = EntryDraft(
            type: .expense,
            amount: 500,
            date: day,
            categoryId: food.id,
            walletId: wallet.id
        )

        try await setup.database.saveEntry(entry, at: setup.now)

        await #expect(throws: AppDatabase.CategoryWriteError.hasEntries) {
            try await setup.database.deleteCategory(food.id)
        }
    }

    @Test
    func hidesAndShowsCategory() async throws {
        let setup = try await Setup()
        let food = try await setup.category(named: "食費")

        try await setup.database.setCategoryHidden(
            food.id,
            isHidden: true,
            at: setup.now
        )
        let hiddenOptions = try await setup.database.entryOptions()

        try await setup.database.setCategoryHidden(
            food.id,
            isHidden: false,
            at: setup.now
        )
        let shownOptions = try await setup.database.entryOptions()

        #expect(!hiddenOptions.expenseCategories.contains { $0.id == food.id })
        #expect(shownOptions.expenseCategories.contains { $0.id == food.id })
    }
}

extension CategoryWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
        let draft: CategoryDraft
    }
}

extension CategoryWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)

        let draft = CategoryDraft(
            kind: .expense,
            name: "外食",
            mark: .glyph(.cafe),
            color: "#E07A5F"
        )

        self.init(database: database, now: now, draft: draft)
    }

    func category(named name: String) async throws -> EntryCategory {
        let list = try await database.categoryList()
        return try #require(list.categories.first { $0.name == name })
    }

    func expenseCategories() async throws -> [EntryCategory] {
        let list = try await database.categoryList()
        return list.categories.filter { $0.kind == .expense }
    }
}
