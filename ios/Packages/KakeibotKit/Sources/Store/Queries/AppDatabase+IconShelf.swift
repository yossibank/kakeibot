import Core
import GRDB

public extension AppDatabase {
    func iconShelfUpdates() -> some AsyncSequence<IconShelf, any Error> {
        ValueObservation
            .tracking(Self.iconShelf)
            .values(in: writer)
    }

    func iconShelf() async throws -> IconShelf {
        try await writer.read(Self.iconShelf)
    }
}

private extension AppDatabase {
    static func iconShelf(in db: Database) throws -> IconShelf {
        let shelfIcons = try ShelfIcon.unarchivedInOrder().fetchAll(db)
        let iconIds = shelfIcons.map(\.iconId)
        let pairs = try Icon.fetchAll(db, keys: iconIds).map { ($0.id, $0) }
        let icons = Dictionary(uniqueKeysWithValues: pairs)

        return IconShelf(
            shelfIcons: shelfIcons,
            icons: icons
        )
    }
}
