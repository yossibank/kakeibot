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
    func savesOnlyTagsOfCategory() async throws {
        let setup = try await Setup()
        let food = try await setup.category(named: "食費")
        let drafts = [EntryTagDraft(name: "朝ごはん")]

        let saved = try await setup.database.saveTags(drafts, for: food.id, at: setup.now)
        let tags = try await setup.foodTags()
        let category = try await setup.category(named: "食費")

        #expect(saved.map(\.id) == tags.map(\.id))
        #expect(tags.map(\.name) == ["朝ごはん"])
        #expect(category == food)
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
    func restoresArchivedTagWithSameName() async throws {
        let setup = try await Setup()
        try await setup.saveFood(tags: ["朝ごはん", "昼ごはん"])
        let before = try await setup.foodTags()
        let kept = EntryTagDraft(before[1])
        let restored = EntryTagDraft(name: " 朝ごはん ")

        try await setup.saveFood([kept])
        try await setup.saveFood([kept, restored])
        let after = try await setup.foodTags()
        let options = try await setup.database.entryOptions()
        let all = options.tags.filter { $0.categoryId == before[0].categoryId }

        #expect(after.map(\.id) == [before[1].id, before[0].id])
        #expect(after.map(\.sortOrder) == [0, 1])
        #expect(all.count == 2)
    }

    @Test
    func rejectsDuplicateTagName() async throws {
        let setup = try await Setup()

        await #expect(throws: EntryTagDraft.Problem.duplicateName) {
            try await setup.saveFood(tags: ["朝ごはん", "朝ごはん "])
        }
    }

    @Test
    func hidesArchivedTagFromTemplateDetail() async throws {
        let setup = try await Setup()
        try await setup.saveFood(tags: ["朝ごはん"])
        let tag = try #require(try await setup.foodTags().first)
        let entry = try await setup.entryDraft()

        let draft = EntryTemplateDraft(
            name: "朝",
            type: .expense,
            amount: 500,
            categoryId: entry.categoryId,
            tagId: tag.id,
            walletId: entry.walletId
        )

        let template = try await setup.database.saveTemplate(draft, at: setup.now)
        let before = try await setup.database.entryList().detailParts(for: template)
        try await setup.saveFood([])
        let after = try await setup.database.entryList().detailParts(for: template)

        #expect(before.contains("朝ごはん"))
        #expect(!after.contains("朝ごはん"))
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
        let category = list.categories.first { $0.name == name }
        return try #require(category)
    }

    func saveFood(tags names: [String]) async throws {
        let drafts = names.map { EntryTagDraft(name: $0) }
        try await saveFood(drafts)
    }

    func saveFood(_ tags: [EntryTagDraft]) async throws {
        let food = try await category(named: "食費")
        let list = try await database.categoryList()
        let icon = try #require(list.icons[food.iconId])
        let draft = CategoryDraft(food, icon: icon)

        try await database.saveCategory(draft, tags: tags, editing: food.id, at: now)
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
