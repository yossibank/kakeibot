import Core
import Foundation
import GRDB

public extension AppDatabase {
    func insertDefaultsIfEmpty(at now: Date) throws {
        try writer.write { db in
            guard try Wallet.fetchCount(db) == 0, try EntryCategory.fetchCount(db) == 0 else {
                return
            }

            try Self.insertDefaults(into: db, at: now)
        }
    }
}

private extension AppDatabase {
    struct Seed {
        let name: String
        let glyph: Icon.Glyph
        let color: String
    }

    static let wallets: [(Seed, Wallet.Kind)] = [
        (Seed(name: "財布", glyph: .cash, color: "#C9A465"), .cash),
        (Seed(name: "銀行", glyph: .bank, color: "#4A6FA5"), .bank)
    ]

    static let expenseCategories: [Seed] = [
        Seed(name: "食費", glyph: .food, color: "#E07A5F"),
        Seed(name: "日用品", glyph: .daily, color: "#81B29A"),
        Seed(name: "交通", glyph: .transit, color: "#3D5A80"),
        Seed(name: "交際", glyph: .social, color: "#F2CC8F"),
        Seed(name: "趣味", glyph: .hobby, color: "#9C6ADE"),
        Seed(name: "衣服", glyph: .clothes, color: "#5FA8D3"),
        Seed(name: "美容", glyph: .beauty, color: "#E5989B"),
        Seed(name: "医療", glyph: .medical, color: "#6CBF84"),
        Seed(name: "住まい", glyph: .home, color: "#B08968"),
        Seed(name: "通信", glyph: .phone, color: "#577590"),
        Seed(name: "光熱費", glyph: .utility, color: "#F4A261"),
        Seed(name: "その他", glyph: .other, color: "#8D99AE")
    ]

    static let incomeCategories: [Seed] = [
        Seed(name: "給料", glyph: .salary, color: "#2A9D8F"),
        Seed(name: "臨時収入", glyph: .bonus, color: "#E9C46A"),
        Seed(name: "その他", glyph: .other, color: "#8D99AE")
    ]

    static func insertDefaults(
        into db: Database,
        at now: Date
    ) throws {
        for (order, (seed, kind)) in wallets.enumerated() {
            let icon = try insertIcon(for: seed, into: db, at: now)

            let wallet = Wallet(
                name: seed.name,
                kind: kind,
                iconId: icon.id,
                initialBalance: 0,
                sortOrder: order,
                createdAt: now,
                updatedAt: now
            )

            try wallet.insert(db)
        }

        try insertCategories(expenseCategories, kind: .expense, into: db, at: now)
        try insertCategories(incomeCategories, kind: .income, into: db, at: now)
    }

    static func insertCategories(
        _ seeds: [Seed],
        kind: EntryCategory.Kind,
        into db: Database,
        at now: Date
    ) throws {
        for (order, seed) in seeds.enumerated() {
            let icon = try insertIcon(for: seed, into: db, at: now)

            let category = EntryCategory(
                kind: kind,
                name: seed.name,
                iconId: icon.id,
                sortOrder: order,
                createdAt: now,
                updatedAt: now
            )

            try category.insert(db)
        }
    }

    static func insertIcon(
        for seed: Seed,
        into db: Database,
        at now: Date
    ) throws -> Icon {
        let icon = Icon(
            emoji: nil,
            text: nil,
            glyph: seed.glyph,
            color: seed.color,
            createdAt: now,
            updatedAt: now
        )

        try icon.insert(db)
        return icon
    }
}
