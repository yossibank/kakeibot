import Core
import Foundation
import GRDB

public struct SettingKey<Value: Sendable>: Sendable {
    public let defaultValue: Value

    let read: @Sendable (Database) throws -> Value
    let write: @Sendable (Value, Database) throws -> Void
}

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

public extension SettingKey where Value == ThemeChoice {
    static var theme: Self {
        Self(
            .themeId,
            default: .system,
            decode: { ThemeChoice($0) },
            encode: { $0.text }
        )
    }
}

public extension SettingKey where Value == ThemeCorner {
    static var cornerStyle: Self {
        Self(.cornerStyle, default: .standard)
    }
}

public extension SettingKey where Value == ThemeFont {
    static var fontStyle: Self {
        Self(.fontStyle, default: .mincho)
    }

    static var textFontStyle: Self {
        Self(.textFontStyle, default: .gothic)
    }
}

public extension SettingKey where Value == ThemeTextSize {
    static var textSize: Self {
        Self(.textSize, default: .standard)
    }
}

public extension SettingKey where Value == ThemeRowSpacing {
    static var rowSpacing: Self {
        Self(.rowSpacing, default: .standard)
    }
}

public extension SettingKey where Value == ThemeStampShape {
    static var stampShape: Self {
        Self(.stampShape, default: .circle)
    }
}

public extension SettingKey where Value == ThemeBackdrop {
    static var backdrop: Self {
        Self(
            .backdrop,
            default: .plain,
            decode: { text in
                ThemeBackdrop(rawValue: text) ?? (text == "washi" ? .ruled : nil)
            },
            encode: { $0.rawValue }
        )
    }
}

public extension SettingKey where Value == TemplateOrder {
    static var templateOrder: Self {
        Self(.templateOrder, default: .manual)
    }
}

public extension SettingKey where Value == [HomeSection] {
    static var homeSections: Self {
        Self(
            .homeSections,
            default: HomeSection.standard,
            decode: { text in
                text.split(separator: ",").compactMap { name in
                    HomeSection(rawValue: String(name))
                }
            },
            encode: { sections in
                sections.map(\.rawValue).joined(separator: ",")
            }
        )
    }
}

public extension SettingKey where Value == Set<HomeSection> {
    static var homeHiddenSections: Self {
        Self(
            .homeHiddenSections,
            default: [],
            decode: { text in
                let sections = text.split(separator: ",").compactMap { name in
                    HomeSection(rawValue: String(name))
                }

                return Set(sections)
            },
            encode: { sections in
                let names = sections.map(\.rawValue).sorted()

                return names.isEmpty ? nil : names.joined(separator: ",")
            }
        )
    }
}

public extension SettingKey where Value == RecordsLayout {
    static var recordsLayout: Self {
        Self(.recordsLayout, default: .calendar)
    }
}

public extension SettingKey where Value == ReviewPeriod.Scale {
    static var reviewScale: Self {
        Self(.reviewScale, default: .month)
    }
}

public extension SettingKey where Value == ReviewKind {
    static var reviewKind: Self {
        Self(.reviewKind, default: .expense)
    }
}

public extension SettingKey where Value == Set<SettingsScreen> {
    static var closedHints: Self {
        Self(screens: .closedHints)
    }

    static var closedHiddenLists: Self {
        Self(screens: .closedHiddenLists)
    }
}

public extension SettingKey where Value == [String] {
    static var recentSearches: Self {
        Self(
            .recentSearches,
            default: [],
            decode: { text in
                text.split(separator: "\n").map(String.init)
            },
            encode: { words in
                words.isEmpty ? nil : words.joined(separator: "\n")
            }
        )
    }
}

public extension SettingKey where Value == WidgetRecord? {
    static var widgetEntry: Self {
        Self(
            .widgetEntry,
            default: nil,
            decode: { WidgetRecord($0) },
            encode: { $0?.text }
        )
    }
}

public extension SettingKey where Value == EntryCategory.ID? {
    static var feeCategory: Self {
        Self(
            .feeCategoryId,
            default: nil,
            decode: { EntryCategory.ID($0) },
            encode: { $0?.description }
        )
    }

    static var transferOutCategory: Self {
        Self(
            .transferOutCategoryId,
            default: nil,
            decode: { EntryCategory.ID($0) },
            encode: { $0?.description }
        )
    }

    static var transferInCategory: Self {
        Self(
            .transferInCategoryId,
            default: nil,
            decode: { EntryCategory.ID($0) },
            encode: { $0?.description }
        )
    }
}

public extension SettingKey where Value == Date? {
    static var backupExportedAt: Self {
        Self(
            .backupExportedAt,
            default: nil,
            decode: { try? Date($0, strategy: .iso8601) },
            encode: { $0?.formatted(.iso8601) }
        )
    }
}

public extension SettingKey where Value == String? {
    static var reviewRequestedVersion: Self {
        Self(
            .reviewRequestedVersion,
            default: nil,
            decode: { $0 },
            encode: { $0 }
        )
    }
}

public extension SettingKey where Value == Bool {
    static var onboardingCompleted: Self {
        Self(flag: .onboardingCompleted)
    }

    static var setupCardClosed: Self {
        Self(flag: .setupCardClosed)
    }

    static var entryOpened: Self {
        Self(flag: .entryOpened)
    }

    static var settingsOpened: Self {
        Self(flag: .settingsOpened)
    }

    static var tabTitles: Self {
        Self(switch: .tabTitles)
    }

    static var entryStartsWithAmount: Self {
        Self(switch: .entryStartsWithAmount)
    }

    static var haptics: Self {
        Self(switch: .haptics)
    }

    static var decorations: Self {
        Self(switch: .decorations)
    }
}

extension SettingKey {
    init(
        _ key: Setting.Key,
        default defaultValue: Value,
        decode: @escaping @Sendable (String) -> Value?,
        encode: @escaping @Sendable (Value) -> String?
    ) {
        self.defaultValue = defaultValue

        self.read = { db in
            let setting = try Setting.fetchOne(db, key: key)
            return setting.flatMap { decode($0.value) } ?? defaultValue
        }

        self.write = { value, db in
            guard let text = encode(value) else {
                _ = try Setting.deleteOne(db, key: key)
                return
            }

            let setting = Setting(key: key, value: text)

            try setting.save(db)
        }
    }
}

extension SettingKey where Value: RawRepresentable, Value.RawValue == String {
    init(
        _ key: Setting.Key,
        default defaultValue: Value
    ) {
        self.init(
            key,
            default: defaultValue,
            decode: { Value(rawValue: $0) },
            encode: { $0.rawValue }
        )
    }
}

extension SettingKey where Value == Set<SettingsScreen> {
    init(
        screens key: Setting.Key,
        default defaultValue: Value = []
    ) {
        self.init(
            key,
            default: defaultValue,
            decode: { text in
                let screens = text.split(separator: ",").compactMap { name in
                    SettingsScreen(rawValue: String(name))
                }

                return Set(screens)
            },
            encode: { screens in
                let names = screens.map(\.rawValue).sorted()

                return names.isEmpty ? nil : names.joined(separator: ",")
            }
        )
    }
}

extension SettingKey where Value == Bool {
    init(flag key: Setting.Key) {
        self.init(
            key,
            default: false,
            decode: { $0 == "true" },
            encode: { $0 ? "true" : nil }
        )
    }

    init(switch key: Setting.Key) {
        self.init(
            key,
            default: true,
            decode: { $0 != "false" },
            encode: { $0 ? nil : "false" }
        )
    }
}
