import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct CategoryEditModelTests {
    @Test
    func keepsOneEmojiAndShortText() throws {
        let database = try Self.database()
        let model = CategoryEditModel(parts: .system(database), kind: .expense)

        model.state.icon.inputEmoji("ab🍙")
        let emoji = model.state.icon.emoji

        model.state.icon.inputEmoji("🍙🐶")
        let lastEmoji = model.state.icon.emoji

        model.state.icon.inputEmoji("abc")
        let noEmoji = model.state.icon.emoji

        model.state.icon.inputText("サブスク")

        #expect(emoji == "🍙")
        #expect(lastEmoji == "🐶")
        #expect(noEmoji.isEmpty)
        #expect(model.state.icon.text == "サブス")
    }

    @Test
    func savesNewCategory() async throws {
        let database = try Self.database()
        let model = CategoryEditModel(parts: .system(database), kind: .income)
        model.state.name = "配当"
        model.state.icon.glyph = .invest

        let canSaveBeforeName = CategoryEditModel(parts: .system(database), kind: .income)
            .canSave
        let saved = await model.save()
        let list = try await database.categoryList()
        let category = list.categories.first { $0.name == "配当" }

        #expect(!canSaveBeforeName)
        #expect(saved?.id == category?.id)
        #expect(category?.kind == .income)
        #expect(category?.sortOrder == 3)
    }

    @Test
    func loadsExistingCategory() async throws {
        let database = try Self.database()
        let list = try await database.categoryList()
        let food = try #require(list.categories.first { $0.name == "食費" })
        let model = CategoryEditModel(
            parts: .system(database),
            kind: .expense,
            editing: food.id
        )

        await model.load()

        #expect(model.isEditing)
        #expect(model.state.name == "食費")
        #expect(model.state.icon.markKind == .glyph)
        #expect(model.state.icon.glyph == .food)
        #expect(model.state.icon.color == "#E07A5F")
        #expect(!model.input.isHidden)
        #expect(!model.isChanged)
    }

    @Test
    func knowsWhetherCategoryHasEntries() async throws {
        let database = try Self.database()
        let options = try await database.entryOptions()
        let used = options.expenseCategories[0]
        let unused = options.expenseCategories[1]
        let walletId = try #require(options.wallets.first?.id)
        let today = LocalDate(Date(), in: .current)

        let draft = EntryDraft(
            type: .expense,
            amount: 500,
            date: today,
            categoryId: used.id,
            walletId: walletId
        )

        try await database.saveEntry(draft, at: Date())
        let usedModel = CategoryEditModel(
            parts: .system(database),
            kind: .expense,
            editing: used.id
        )
        let unusedModel = CategoryEditModel(
            parts: .system(database),
            kind: .expense,
            editing: unused.id
        )

        await usedModel.load()
        await unusedModel.load()

        #expect(usedModel.input.hasEntries)
        #expect(!unusedModel.input.hasEntries)
    }

    @Test
    func tracksChangesFromStart() throws {
        let database = try Self.database()
        let model = CategoryEditModel(parts: .system(database), kind: .expense)
        let start = model.isChanged

        model.state.name = "外食"
        let named = model.isChanged

        model.state.name = ""
        let cleared = model.isChanged

        #expect(model.state.icon.glyph == .food)
        #expect(!start)
        #expect(named)
        #expect(!cleared)
    }

    @Test
    func editsAndSavesTags() async throws {
        let database = try Self.database()
        let list = try await database.categoryList()
        let food = try #require(list.categories.first { $0.name == "食費" })
        let model = CategoryEditModel(
            parts: .system(database),
            kind: .expense,
            editing: food.id
        )

        await model.load()

        let added = model.state.addTag("朝ごはん") && model.state.addTag("昼ごはん")
        let blankAdded = model.state.addTag(" ")
        let blankError = model.state.tagProblem
        let breakfast = try #require(model.state.tags.first)
        let lunch = try #require(model.state.tags.last)
        let renamed = model.state.renameTag(lunch.id, to: "ランチ")
        model.state.removeTag(breakfast.id)
        let snackAdded = model.state.addTag("おやつ")
        let snack = try #require(model.state.tags.last)
        model.state.moveTag(snack.id, to: 0)

        let changed = model.isChanged
        _ = await model.save()
        let saved = try await database.categoryList().tags

        #expect(added && renamed && snackAdded)
        #expect(!blankAdded)
        #expect(blankError == "タグの名前を入れてください")
        #expect(model.state.tagProblem == nil)
        #expect(changed)
        #expect(saved.map(\.name) == ["おやつ", "ランチ"])
        #expect(saved.allSatisfy { $0.categoryId == food.id })
    }

    @Test
    func rejectsTagWithNameOfAnotherTag() throws {
        let database = try Self.database()
        let model = CategoryEditModel(parts: .system(database), kind: .expense)

        _ = model.state.addTag("朝ごはん")
        _ = model.state.addTag("昼ごはん")
        let duplicated = model.state.addTag(" 朝ごはん ")
        let addError = model.state.tagProblem
        let lunch = try #require(model.state.tags.last)
        let renamed = model.state.renameTag(lunch.id, to: "朝ごはん")
        let renameError = model.state.tagProblem
        let kept = model.state.renameTag(lunch.id, to: "昼ごはん")

        #expect(!duplicated)
        #expect(addError == "同じ名前のタグがあります")
        #expect(!renamed)
        #expect(renameError == "同じ名前のタグがあります")
        #expect(kept)
        #expect(model.state.tags.count == 2)
    }

    @Test
    func keepsTagChangesUnsavedUntilSave() async throws {
        let database = try Self.database()
        let list = try await database.categoryList()
        let food = try #require(list.categories.first { $0.name == "食費" })
        let model = CategoryEditModel(
            parts: .system(database),
            kind: .expense,
            editing: food.id
        )
        await model.load()

        _ = model.state.addTag(" 朝ごはん ")
        _ = model.state.addTag("昼ごはん")
        let changed = model.isChanged
        let discarded = try await database.categoryList().tags

        _ = await model.save()
        let saved = try await database.categoryList().tags

        #expect(changed)
        #expect(discarded.isEmpty)
        #expect(saved.map(\.name) == ["朝ごはん", "昼ごはん"])
        #expect(saved.allSatisfy { $0.categoryId == food.id })
    }

    @Test
    func keepsRemovedTagUntilSave() async throws {
        let database = try Self.database()
        let list = try await database.categoryList()
        let food = try #require(list.categories.first { $0.name == "食費" })
        let model = CategoryEditModel(
            parts: .system(database),
            kind: .expense,
            editing: food.id
        )
        await model.load()
        _ = model.state.addTag("朝ごはん")
        _ = await model.save()
        let reopened = CategoryEditModel(
            parts: .system(database),
            kind: .expense,
            editing: food.id
        )
        await reopened.load()
        let tag = try #require(reopened.state.tags.first)

        reopened.state.removeTag(tag.id)
        let changed = reopened.isChanged
        let stored = try await database.categoryList().tags

        #expect(changed)
        #expect(stored.map(\.name) == ["朝ごはん"])
        #expect(stored.first?.archivedAt == nil)
    }

    @Test
    func savesTagsWithNewCategory() async throws {
        let database = try Self.database()
        let model = CategoryEditModel(parts: .system(database), kind: .expense)
        model.state.name = "外食"

        _ = model.state.addTag("朝ごはん")
        let before = try await database.categoryList().tags
        let category = try #require(await model.save())
        let after = try await database.categoryList().tags

        #expect(before.isEmpty)
        #expect(after.map(\.name) == ["朝ごはん"])
        #expect(after.first?.categoryId == category.id)
    }

    @Test
    func reportsReadyAfterLoading() async throws {
        let database = try Self.database()
        let category = try #require(await database.categoryList().categories.first)
        let adding = CategoryEditModel(parts: .system(database), kind: .expense)
        let editing = CategoryEditModel(
            parts: .system(database),
            kind: .expense,
            editing: category.id
        )
        let start = editing.state.ready

        await adding.start()
        await editing.start()

        #expect(adding.state.ready != start)
        #expect(editing.state.ready != start)
        #expect(editing.state.name == category.name)
    }
}

private extension CategoryEditModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        return database
    }
}
