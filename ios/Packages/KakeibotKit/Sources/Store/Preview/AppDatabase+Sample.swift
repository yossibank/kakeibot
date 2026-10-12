#if DEBUG
import Core
import Foundation
import GRDB

public extension AppDatabase {
    func writeSampleEntries(
        count: Int,
        on date: LocalDate,
        at now: Date
    ) async throws {
        try await writer.write { db in
            let owner = try SampleOwner(fetchingOrInsertingIn: db, at: now)

            for index in 0..<count {
                let amount = 100 + index % 900

                let entry = Entry(
                    type: .expense,
                    amount: amount,
                    date: date,
                    categoryId: owner.categoryId,
                    walletId: owner.walletId,
                    createdAt: now,
                    updatedAt: now
                )

                try entry.insert(db)
            }
        }
    }

    func entryCount() async throws -> Int {
        try await writer.read { try Entry.fetchCount($0) }
    }
}

private struct SampleOwner {
    let walletId: Wallet.ID
    let categoryId: EntryCategory.ID
}

private extension SampleOwner {
    init(
        fetchingOrInsertingIn db: Database,
        at now: Date
    ) throws {
        if let wallet = try Wallet.fetchOne(db), let category = try EntryCategory.fetchOne(db) {
            self.init(walletId: wallet.id, categoryId: category.id)
            return
        }

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

        try icon.insert(db)
        try wallet.insert(db)
        try category.insert(db)
        self.init(walletId: wallet.id, categoryId: category.id)
    }
}
#endif
