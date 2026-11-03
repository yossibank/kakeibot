import Core
import GRDB

public extension AppDatabase {
    func noSpendDayUpdates() -> some AsyncSequence<Set<LocalDate>, any Error> {
        ValueObservation.tracking(Self.noSpendDays).removeDuplicates().values(in: writer)
    }
}

extension AppDatabase {
    static func noSpendDays(in db: Database) throws -> Set<LocalDate> {
        let dates = try NoSpendDay.fetchAll(db).map(\.date)
        return Set(dates)
    }
}
