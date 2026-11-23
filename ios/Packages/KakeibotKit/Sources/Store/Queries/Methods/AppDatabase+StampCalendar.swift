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
        let stampPairs = stamps.map { ($0.date, $0) }
        let stampsByDate = Dictionary(uniqueKeysWithValues: stampPairs)
        let iconIds = stamps.map(\.iconId)
        let iconsByID = try Icon.byID(iconIds, in: db)
        return StampCalendar(stamps: stampsByDate, icons: iconsByID)
    }
}
