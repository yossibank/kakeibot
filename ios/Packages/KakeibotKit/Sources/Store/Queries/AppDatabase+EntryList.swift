import Core
import GRDB

public extension AppDatabase {
    func entryListUpdates() -> some AsyncSequence<EntryList, any Error> {
        ValueObservation
            .tracking(Self.entryList)
            .values(in: writer)
    }

    func entryList() async throws -> EntryList {
        try await writer.read(Self.entryList)
    }

    func entryOptions() async throws -> EntryOptions {
        try await writer.read(Self.entryOptions)
    }

    func entry(_ id: Entry.ID) async throws -> Entry? {
        try await writer.read { try Entry.fetchOne($0, key: id) }
    }

    func recentMemos(limit: Int) async throws -> [String] {
        try await writer.read { db in
            try String.fetchAll(db, sql: Self.recentMemosSQL, arguments: [limit])
        }
    }
}

private extension AppDatabase {
    static let recentMemosSQL = """
    SELECT memo FROM entry
    WHERE memo IS NOT NULL AND memo <> ''
    GROUP BY memo
    ORDER BY MAX(created_at) DESC
    LIMIT ?
    """

    static func entryList(in db: Database) throws -> EntryList {
        let entries = try Entry.fetchAll(db)
        let days = EntryDay.grouping(entries)
        let categories = try byID(EntryCategory.fetchAll(db))
        let wallets = try byID(Wallet.fetchAll(db))
        let icons = try byID(Icon.fetchAll(db))

        return EntryList(
            days: days,
            categories: categories,
            wallets: wallets,
            icons: icons
        )
    }

    static func entryOptions(in db: Database) throws -> EntryOptions {
        let categories = try EntryCategory.unarchivedInOrder().fetchAll(db)
        let wallets = try Wallet.unarchivedInOrder().fetchAll(db)
        let expenseCategories = categories.filter { $0.kind == .expense }
        let incomeCategories = categories.filter { $0.kind == .income }
        let icons = try byID(Icon.fetchAll(db))

        return EntryOptions(
            expenseCategories: expenseCategories,
            incomeCategories: incomeCategories,
            wallets: wallets,
            icons: icons
        )
    }

    static func byID<Item: Identifiable>(_ items: [Item]) -> [Item.ID: Item] {
        Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }
}
