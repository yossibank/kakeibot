import Core
import GRDB

public extension AppDatabase {
    func shelfIconListUpdates() -> some AsyncSequence<ShelfIconList, any Error> {
        ValueObservation.tracking(Self.shelfIconList).values(in: writer)
    }

    func shelfIconList() async throws -> ShelfIconList {
        try await writer.read(Self.shelfIconList)
    }
}

private extension AppDatabase {
    static func shelfIconList(in db: Database) throws -> ShelfIconList {
        let shelfIcons = try ShelfIcon.order(ShelfIcon.sortOrder).fetchAll(db)
        let iconIds = shelfIcons.map(\.iconId)
        let icons = try Icon.byID(iconIds, in: db)
        return ShelfIconList(shelfIcons: shelfIcons, icons: icons)
    }
}
