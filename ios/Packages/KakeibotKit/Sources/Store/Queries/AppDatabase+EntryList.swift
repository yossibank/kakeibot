import Core
import GRDB

public extension AppDatabase {
    func entryListUpdates() -> some AsyncSequence<EntryList, any Error> {
        entryListObservation.values()
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

extension AppDatabase {
    static func entryList(in db: Database) throws -> EntryList {
        let entries = try Entry.fetchAll(db)
        let days = EntryDay.grouping(entries)
        let categories = try byID(EntryCategory.self, in: db)
        let tags = try byID(EntryTag.self, in: db)
        let wallets = try byID(Wallet.self, in: db)
        let valuations = try Valuation.fetchAll(db)
        let icons = try byID(Icon.self, in: db)

        let cardBills = try recurrings(in: db)
            .filter { $0.type == .transfer && $0.closingDay != nil }

        return EntryList(
            days: days,
            categories: categories,
            tags: tags,
            wallets: wallets,
            valuations: valuations,
            icons: icons,
            cardBills: cardBills
        )
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

    static func entryOptions(in db: Database) throws -> EntryOptions {
        let categories = try EntryCategory
            .unarchivedInOrder()
            .filter(Column("wallet_id") == nil)
            .fetchAll(db)

        let tags = try EntryTag
            .order(EntryTag.sortOrder)
            .filter(sql: "category_id IN (SELECT id FROM category WHERE wallet_id IS NULL)")
            .fetchAll(db)

        let sharedCategories = try EntryCategory
            .unarchivedInOrder()
            .filter(Column("wallet_id") != nil)
            .fetchAll(db)

        let sharedTags = try EntryTag
            .order(EntryTag.sortOrder)
            .filter(sql: "category_id IN (SELECT id FROM category WHERE wallet_id IS NOT NULL)")
            .fetchAll(db)

        let wallets = try Wallet.unarchivedInOrder().fetchAll(db)
        let expenseCategories = categories.filter { $0.kind == .expense }
        let incomeCategories = categories.filter { $0.kind == .income }
        let icons = try byID(Icon.self, in: db)

        return EntryOptions(
            expenseCategories: expenseCategories,
            incomeCategories: incomeCategories,
            tags: tags,
            wallets: wallets,
            icons: icons,
            sharedCategories: sharedCategories,
            sharedTags: sharedTags
        )
    }

    static func byID<Record: StoreRecord & Identifiable>(
        _ type: Record.Type,
        in db: Database
    ) throws -> [Record.ID: Record] {
        let pairs = try Record.fetchAll(db).map { ($0.id, $0) }
        return Dictionary(uniqueKeysWithValues: pairs)
    }
}
