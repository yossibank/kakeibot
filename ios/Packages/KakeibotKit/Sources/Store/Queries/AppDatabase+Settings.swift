import Core
import GRDB

public extension AppDatabase {
    func monthStartDayUpdates()
        -> some AsyncSequence<MonthStartDay, any Error> {
        ValueObservation
            .tracking(Self.monthStartDay)
            .removeDuplicates()
            .values(in: writer)
    }

    func monthStartDay() async throws -> MonthStartDay {
        try await writer.read(Self.monthStartDay)
    }

    func isOnboardingCompleted() async throws -> Bool {
        try await writer.read { db in
            let key = Setting.Key.onboardingCompleted
            let setting = try Setting.fetchOne(db, key: key)
            return setting?.value == "true"
        }
    }
}

private extension AppDatabase {
    static func monthStartDay(in db: Database) throws -> MonthStartDay {
        let key = Setting.Key.monthStartDay
        let setting = try Setting.fetchOne(db, key: key)
        let day = setting.flatMap { Int($0.value) }
        return day.flatMap(MonthStartDay.init) ?? .first
    }
}
