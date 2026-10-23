import Core
import Foundation
import Store
import Testing

struct DefaultsTests {
    @Test
    func insertsWalletsAndCategoriesOnce() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        try database.insertDefaultsIfEmpty(at: now)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()

        #expect(options.wallets.map(\.name) == ["財布", "銀行"])
        #expect(options.expenseCategories.count == 12)
        #expect(options.incomeCategories.map(\.name) == ["給料", "臨時収入", "その他"])
        #expect(options.icons.count == 17)
    }

    @Test
    func addsStarterTemplatesOnlyWhenEmpty() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)

        try await database.insertTemplatesIfEmpty(at: now)
        try await database.insertTemplatesIfEmpty(at: now)
        let templates = try await database.templates()

        #expect(templates.count == 4)
    }

    @Test
    func skipsWhenWalletsExist() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let icon = Icon(
            emoji: "🍙",
            text: nil,
            color: "#C9A465",
            createdAt: now,
            updatedAt: now
        )

        let wallet = Wallet(
            name: "財布",
            kind: .cash,
            iconId: icon.id,
            initialBalance: 0,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )

        let category = EntryCategory(
            kind: .expense,
            name: "食費",
            iconId: icon.id,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )

        try await database.writer.write { db in
            try icon.insert(db)
            try wallet.insert(db)
            try category.insert(db)
        }

        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()

        #expect(options.wallets.count == 1)
        #expect(options.expenseCategories.count == 1)
    }

    @Test
    func insertsShelfOnce() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        try database.insertShelfIfEmpty(at: now)
        try database.insertShelfIfEmpty(at: now)
        let shelf = try await database.iconShelf()
        let glyphs = shelf.shelfIcons.map { shelf.icons[$0.iconId]?.glyph }

        #expect(shelf.shelfIcons.map(\.sortOrder) == Array(0..<8))
        #expect(glyphs.first == .star)
        #expect(glyphs.allSatisfy { $0 != nil })
    }

    @Test
    func skipsShelfWhenAllAreHidden() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertShelfIfEmpty(at: now)
        let inserted = try await database.iconShelf()

        for shelfIcon in inserted.shelfIcons {
            try await database.setShelfIconHidden(
                shelfIcon.id,
                isHidden: true,
                at: now
            )
        }

        try database.insertShelfIfEmpty(at: now)
        let shelf = try await database.iconShelf()

        #expect(shelf.shelfIcons.count == 8)
        #expect(shelf.shelfIcons.allSatisfy { $0.archivedAt != nil })
    }
}
