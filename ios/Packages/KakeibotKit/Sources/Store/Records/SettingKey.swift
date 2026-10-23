import Core

public struct SettingKey<Value: Sendable>: Sendable {
    let key: Setting.Key
    let defaultValue: Value
    let decode: @Sendable (String) -> Value?
    let encode: @Sendable (Value) -> String?
}

public extension SettingKey where Value == MonthStartDay {
    static var monthStartDay: Self {
        Self(
            .monthStartDay,
            default: .first,
            decode: { Int($0).flatMap(MonthStartDay.init) },
            encode: { String($0.day) }
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
        Self(.launchScreen, default: .entry)
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

public extension SettingKey where Value == TemplateOrder {
    static var templateOrder: Self {
        Self(.templateOrder, default: .manual)
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

public extension SettingKey where Value == Bool {
    static var entryStartsWithAmount: Self {
        Self(flag: .entryStartsWithAmount)
    }

    static var categoryMenuOpened: Self {
        Self(flag: .categoryMenuOpened)
    }

    static var onboardingCompleted: Self {
        Self(flag: .onboardingCompleted)
    }
}

extension SettingKey {
    init(
        _ key: Setting.Key,
        default defaultValue: Value,
        decode: @escaping @Sendable (String) -> Value?,
        encode: @escaping @Sendable (Value) -> String?
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.decode = decode
        self.encode = encode
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
}
