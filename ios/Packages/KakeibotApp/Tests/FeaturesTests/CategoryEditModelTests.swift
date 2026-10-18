import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct CategoryEditModelTests {
    @Test
    func keepsOneEmojiAndShortText() throws {
        let database = try Self.database()
        let model = CategoryEditModel(database: database, kind: .expense)

        model.icon.inputEmoji("ab🍙")
        let emoji = model.icon.emoji

        model.icon.inputEmoji("🍙🐶")
        let lastEmoji = model.icon.emoji

        model.icon.inputEmoji("abc")
        let noEmoji = model.icon.emoji

        model.icon.inputText("サブスク")

        #expect(emoji == "🍙")
        #expect(lastEmoji == "🐶")
        #expect(noEmoji.isEmpty)
        #expect(model.icon.text == "サブス")
    }

    @Test
    func savesNewCategory() async throws {
        let database = try Self.database()
        let model = CategoryEditModel(database: database, kind: .income)
        model.name = "配当"
        model.icon.glyph = .invest
        let canSaveBeforeName = CategoryEditModel(
            database: database,
            kind: .income
        ).canSave

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
            database: database,
            kind: .expense,
            editing: food.id
        )
        await model.load()

        #expect(model.isEditing)
        #expect(model.name == "食費")
        #expect(model.icon.markKind == .glyph)
        #expect(model.icon.glyph == .food)
        #expect(model.icon.color == "#E07A5F")
        #expect(!model.isHidden)
        #expect(!model.isChanged)
    }

    @Test
    func tracksChangesFromStart() throws {
        let database = try Self.database()
        let model = CategoryEditModel(database: database, kind: .expense)
        let start = model.isChanged

        model.name = "外食"
        let named = model.isChanged

        model.name = ""
        let cleared = model.isChanged

        #expect(model.icon.glyph == .food)
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
            database: database,
            kind: .expense,
            editing: food.id
        )
        await model.load()

        let added = model.addTag("朝ごはん") && model.addTag("昼ごはん")
        let blankAdded = model.addTag(" ")
        let blankError = model.tagProblem
        let breakfast = try #require(model.tags.first)
        let lunch = try #require(model.tags.last)
        let renamed = model.renameTag(lunch.id, to: "ランチ")
        model.removeTag(breakfast.id)
        let snackAdded = model.addTag("おやつ")
        let snack = try #require(model.tags.last)
        model.moveTag(snack.id, to: 0)

        let changed = model.isChanged
        _ = await model.save()
        let saved = try await database.categoryList().tags

        #expect(added && renamed && snackAdded)
        #expect(!blankAdded)
        #expect(blankError == "タグの名前を入れてください")
        #expect(model.tagProblem == nil)
        #expect(changed)
        #expect(saved.map(\.name) == ["おやつ", "ランチ"])
        #expect(saved.allSatisfy { $0.categoryId == food.id })
    }
}

private extension CategoryEditModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        return database
    }
}
