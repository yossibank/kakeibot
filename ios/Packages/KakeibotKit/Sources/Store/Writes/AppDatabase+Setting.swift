import Core
import GRDB

public extension AppDatabase {
    func setMonthStartDay(_ startDay: MonthStartDay) async throws {
        try await writer.write { db in
            let setting = Setting(
                key: .monthStartDay,
                value: String(startDay.day)
            )

            try setting.save(db)
        }
    }

    func setWeekStart(_ weekStart: Weekday) async throws {
        try await writer.write { db in
            let setting = Setting(key: .weekStart, value: weekStart.rawValue)
            try setting.save(db)
        }
    }

    func setLaunchScreen(_ screen: LaunchScreen) async throws {
        try await writer.write { db in
            let setting = Setting(key: .launchScreen, value: screen.rawValue)
            try setting.save(db)
        }
    }

    func setTemplateOrder(_ order: TemplateOrder) async throws {
        try await writer.write { db in
            let setting = Setting(key: .templateOrder, value: order.rawValue)
            try setting.save(db)
        }
    }

    func setRecordsLayout(_ layout: RecordsLayout) async throws {
        try await writer.write { db in
            let setting = Setting(key: .recordsLayout, value: layout.rawValue)
            try setting.save(db)
        }
    }

    func markCategoryMenuOpened() async throws {
        try await writer.write { db in
            let setting = Setting(key: .categoryMenuOpened, value: "true")
            try setting.save(db)
        }
    }

    func completeOnboarding() async throws {
        try await writer.write { db in
            let setting = Setting(key: .onboardingCompleted, value: "true")
            try setting.save(db)
        }
    }
}
