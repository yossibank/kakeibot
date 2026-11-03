import Core
import Foundation
import GRDB

public extension SettingKey where Value == MonthStartDay {
    static var monthStartDay: Self {
        let day = Self(
            .monthStartDay,
            default: .first,
            decode: { Int($0).flatMap { MonthStartDay($0) } },
            encode: { String($0.day) }
        )

        let shift = SettingKey<HolidayShift>.monthStartShift

        return Self(
            defaultValue: day.defaultValue,
            read: { db in
                let startDay = try day.read(db)
                let holidayShift = try shift.read(db)
                return startDay.shifted(by: holidayShift)
            },
            write: { startDay, db in
                try day.write(startDay, db)
                try shift.write(startDay.shift, db)
            }
        )
    }
}

private extension SettingKey where Value == HolidayShift {
    static var monthStartShift: Self {
        Self(
            .monthStartShift,
            default: .none,
            decode: { HolidayShift(rawValue: $0) },
            encode: { $0 == .none ? nil : $0.rawValue }
        )
    }
}

public extension SettingKey where Value == YearMonth? {
    static var budgetCarryoverFrom: Self {
        Self(
            .budgetCarryoverFrom,
            default: nil,
            decode: { YearMonth($0) },
            encode: { $0?.description }
        )
    }
}

public extension SettingKey where Value == Weekday {
    static var weekStart: Self {
        Self(.weekStart, default: .sunday)
    }
}

public extension SettingKey where Value == ReminderTime? {
    static var reminderTime: Self {
        Self(
            .reminderTime,
            default: nil,
            decode: { ReminderTime($0) },
            encode: { $0?.description }
        )
    }
}

public extension SettingKey where Value == LaunchScreen {
    static var launchScreen: Self {
        Self(.launchScreen, default: .home)
    }
}
