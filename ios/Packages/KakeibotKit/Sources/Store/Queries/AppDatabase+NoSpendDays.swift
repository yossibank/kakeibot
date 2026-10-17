import Core
import GRDB

public extension AppDatabase {
    func noSpendDayUpdates()
        -> some AsyncSequence<Set<LocalDate>, any Error> {
        ValueObservation
            .tracking(Self.noSpendDays)
            .removeDuplicates()
            .values(in: writer)
    }
}

extension AppDatabase {
    static func noSpendDays(in db: Database) throws -> Set<LocalDate> {
        try Set(NoSpendDay.fetchAll(db).map(\.date))
    }
}
