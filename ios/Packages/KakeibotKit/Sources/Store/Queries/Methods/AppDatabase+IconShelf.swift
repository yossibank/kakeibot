import Core
import GRDB

public extension AppDatabase {
    func iconShelfUpdates() -> some AsyncSequence<IconShelf, any Error> {
        ValueObservation.tracking(Self.iconShelf).values(in: writer)
    }

    func iconShelf() async throws -> IconShelf {
        try await writer.read(Self.iconShelf)
    }
}

private extension AppDatabase {
    static func iconShelf(in db: Database) throws -> IconShelf {
        let shelfIcons = try ShelfIcon.order(ShelfIcon.sortOrder).fetchAll(db)
        let iconIds = shelfIcons.map(\.iconId)
        let icons = try Icon.byID(iconIds, in: db)
        return IconShelf(shelfIcons: shelfIcons, icons: icons)
    }
}
