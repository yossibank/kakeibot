import Core
import Foundation
import Store
import Testing

struct TagWriteTests {
    @Test
    func savesTagsInOrder() async throws {
        let setup = try await Setup()

        try await setup.saveFood(tags: ["朝ごはん", " 昼ごはん "])
        let tags = try await setup.foodTags()

        #expect(tags.map(\.name) == ["朝ごはん", "昼ごはん"])
        #expect(tags.map(\.sortOrder) == [0, 1])
    }

    @Test
    func renamesKeptTagsAndArchivesRemovedOnes() async throws {
        let setup = try await Setup()
        try await setup.saveFood(tags: ["朝ごはん", "昼ごはん"])
        let before = try await setup.foodTags()

        let drafts = [
            EntryTagDraft(id: before[1].id, name: "ランチ"),
            EntryTagDraft(name: "おやつ")
        ]

        try await setup.saveFood(drafts)
        let after = try await setup.foodTags()
        let options = try await setup.database.entryOptions()
        let removed = options.tags.first { $0.id == before[0].id }

        #expect(after.map(\.name) == ["ランチ", "おやつ"])
        #expect(after[0].id == before[1].id)
        #expect(removed?.archivedAt == setup.now)
    }

    @Test
    func rejectsUnknownTag() async throws {
        let setup = try await Setup()
        let drafts = [EntryTagDraft(id: EntryTag.ID(), name: "朝ごはん")]

        await #expect(throws: AppDatabase.CategoryWriteError.tagNotFound) {
            try await setup.saveFood(drafts)
        }
    }

    @Test
    func rejectsBlankTagName() async throws {
        let setup = try await Setup()

        await #expect(throws: EntryTagDraft.Problem.emptyName) {
            try await setup.saveFood(tags: ["  "])
        }
    }

    @Test
    func savesEntryWithTagOfItsCategory() async throws {
        let setup = try await Setup()
        try await setup.saveFood(tags: ["昼ごはん"])
        let tag = try #require(try await setup.foodTags().first)
        var draft = try await setup.entryDraft()
        draft.tagId = tag.id

        let entry = try await setup.database.saveEntry(draft, at: setup.now)

        #expect(entry.tagId == tag.id)
    }

    @Test
    func rejectsEntryWithTagOfOtherCategory() async throws {
        let setup = try await Setup()
        try await setup.saveFood(tags: ["昼ごはん"])
        let tag = try #require(try await setup.foodTags().first)
        let other = try await setup.category(named: "日用品")
        var draft = try await setup.entryDraft()
        draft.categoryId = other.id
        draft.tagId = tag.id

        await #expect(throws: AppDatabase.WriteError.tagMismatch) {
            try await setup.database.saveEntry(draft, at: setup.now)
        }
    }

    @Test
    func rejectsTemplateWithTagOfOtherCategory() async throws {
        let setup = try await Setup()
        try await setup.saveFood(tags: ["昼ごはん"])
        let tag = try #require(try await setup.foodTags().first)
        let other = try await setup.category(named: "日用品")
        let entry = try await setup.entryDraft()

        let draft = EntryTemplateDraft(
            name: "ランチ",
            type: .expense,
            amount: 980,
            categoryId: other.id,
            tagId: tag.id,
            walletId: entry.walletId
        )

        await #expect(throws: AppDatabase.TemplateWriteError.tagMismatch) {
            try await setup.database.saveTemplate(draft, at: setup.now)
        }
    }
}

extension TagWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
    }
}

extension TagWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        self.init(database: database, now: now)
    }

    func category(named name: String) async throws -> EntryCategory {
        let list = try await database.categoryList()
        return try #require(list.categories.first { $0.name == name })
    }

    func saveFood(tags names: [String]) async throws {
        try await saveFood(names.map { EntryTagDraft(name: $0) })
    }

    func saveFood(_ tags: [EntryTagDraft]) async throws {
        let food = try await category(named: "食費")
        let list = try await database.categoryList()
        let icon = try #require(list.icons[food.iconId])

        try await database.saveCategory(
            CategoryDraft(food, icon: icon),
            tags: tags,
            editing: food.id,
            at: now
        )
    }

    func foodTags() async throws -> [EntryTag] {
        let food = try await category(named: "食費")
        let list = try await database.categoryList()
        return list.tags.filter { $0.categoryId == food.id }
    }

    func entryDraft() async throws -> EntryDraft {
        let food = try await category(named: "食費")
        let options = try await database.entryOptions()
        let date = try #require(LocalDate("2026-10-03"))

        return EntryDraft(
            type: .expense,
            amount: 980,
            date: date,
            categoryId: food.id,
            walletId: options.wallets[0].id
        )
    }
}
