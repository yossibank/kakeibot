import Core
import GRDB

public extension AppDatabase {
    func stampCalendarUpdates() -> some AsyncSequence<StampCalendar, any Error> {
        ValueObservation.tracking(Self.stampCalendar).removeDuplicates().values(in: writer)
    }

    func stampCalendar() async throws -> StampCalendar {
        try await writer.read(Self.stampCalendar)
    }
}

private extension AppDatabase {
    static func stampCalendar(in db: Database) throws -> StampCalendar {
        let stamps = try CalendarStamp.fetchAll(db)
        let iconIds = stamps.map(\.iconId)
        let icons = try Icon.fetchAll(db, keys: iconIds)
        let stampPairs = stamps.map { ($0.date, $0) }
        let iconPairs = icons.map { ($0.id, $0) }
        let stampsByDate = Dictionary(uniqueKeysWithValues: stampPairs)
        let iconsByID = Dictionary(uniqueKeysWithValues: iconPairs)
        return StampCalendar(stamps: stampsByDate, icons: iconsByID)
    }
}
