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
}
