import Core
import GRDB

public extension AppDatabase {
    func stampBookUpdates() -> some AsyncSequence<StampBook, any Error> {
        ValueObservation.tracking(Self.stampBook).removeDuplicates().values(in: writer)
    }

    func stampBook() async throws -> StampBook {
        try await writer.read(Self.stampBook)
    }
}

private extension AppDatabase {
    static func stampBook(in db: Database) throws -> StampBook {
        let stamps = try CalendarStamp.fetchAll(db)
        let stampPairs = stamps.map { ($0.date, $0) }
        let stampsByDate = Dictionary(uniqueKeysWithValues: stampPairs)
        let iconIds = stamps.map(\.iconId)
        let iconsByID = try Icon.byID(iconIds, in: db)
        return StampBook(stamps: stampsByDate, icons: iconsByID)
    }
}
