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

        model.inputEmoji("ab🍙")
        let emoji = model.emoji

        model.inputEmoji("🍙🐶")
        let lastEmoji = model.emoji

        model.inputEmoji("abc")
        let noEmoji = model.emoji

        model.inputText("サブスク")

        #expect(emoji == "🍙")
        #expect(lastEmoji == "🐶")
        #expect(noEmoji.isEmpty)
        #expect(model.text == "サブス")
    }

    @Test
    func savesNewCategory() async throws {
        let database = try Self.database()
        let model = CategoryEditModel(database: database, kind: .income)
        model.name = "配当"
        model.glyph = .invest
        let canSaveBeforeName = CategoryEditModel(
            database: database,
            kind: .income
        ).canSave

        let saved = await model.save()
        let list = try await database.categoryList()
        let category = list.categories.first { $0.name == "配当" }

        #expect(!canSaveBeforeName)
        #expect(saved)
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
        #expect(model.markKind == .glyph)
        #expect(model.glyph == .food)
        #expect(model.color == "#E07A5F")
        #expect(!model.isHidden)
    }
}

private extension CategoryEditModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        return database
    }
}
