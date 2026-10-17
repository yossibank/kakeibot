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

    func weekStartUpdates() -> some AsyncSequence<Weekday, any Error> {
        ValueObservation
            .tracking(Self.weekStart)
            .removeDuplicates()
            .values(in: writer)
    }

    func weekStart() async throws -> Weekday {
        try await writer.read(Self.weekStart)
    }

    func launchScreen() async throws -> LaunchScreen {
        try await writer.read { db in
            let key = Setting.Key.launchScreen
            let setting = try Setting.fetchOne(db, key: key)
            return setting.flatMap { LaunchScreen(rawValue: $0.value) } ?? .home
        }
    }

    func templateOrder() async throws -> TemplateOrder {
        try await writer.read { db in
            let key = Setting.Key.templateOrder
            let setting = try Setting.fetchOne(db, key: key)
            return setting.flatMap { TemplateOrder(rawValue: $0.value) }
                ?? .manual
        }
    }

    func recordsLayout() async throws -> RecordsLayout {
        try await writer.read { db in
            let key = Setting.Key.recordsLayout
            let setting = try Setting.fetchOne(db, key: key)
            return setting.flatMap { RecordsLayout(rawValue: $0.value) }
                ?? .list
        }
    }

    func reviewScale() async throws -> ReviewPeriod.Scale {
        try await writer.read { db in
            let key = Setting.Key.reviewScale
            let setting = try Setting.fetchOne(db, key: key)
            return setting.flatMap { ReviewPeriod.Scale(rawValue: $0.value) }
                ?? .month
        }
    }

    func reviewKind() async throws -> ReviewKind {
        try await writer.read { db in
            let key = Setting.Key.reviewKind
            let setting = try Setting.fetchOne(db, key: key)
            return setting.flatMap { ReviewKind(rawValue: $0.value) }
                ?? .expense
        }
    }

    func hasOpenedCategoryMenu() async throws -> Bool {
        try await writer.read { db in
            let key = Setting.Key.categoryMenuOpened
            let setting = try Setting.fetchOne(db, key: key)
            return setting?.value == "true"
        }
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

    static func weekStart(in db: Database) throws -> Weekday {
        let key = Setting.Key.weekStart
        let setting = try Setting.fetchOne(db, key: key)
        return setting.flatMap { Weekday(rawValue: $0.value) } ?? .sunday
    }
}
