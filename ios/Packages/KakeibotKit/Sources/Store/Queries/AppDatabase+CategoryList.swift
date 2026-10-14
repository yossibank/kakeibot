import Core
import GRDB

public extension AppDatabase {
    func categoryListUpdates() -> some AsyncSequence<CategoryList, any Error> {
        ValueObservation
            .tracking(Self.categoryList)
            .values(in: writer)
    }

    func categoryList() async throws -> CategoryList {
        try await writer.read(Self.categoryList)
    }
}

private extension AppDatabase {
    static func categoryList(in db: Database) throws -> CategoryList {
        let categories = try EntryCategory
            .order(Column("sort_order"))
            .fetchAll(db)

        let pairs = try Icon.fetchAll(db).map { ($0.id, $0) }
        let icons = Dictionary(uniqueKeysWithValues: pairs)
        return CategoryList(categories: categories, icons: icons)
    }
}
