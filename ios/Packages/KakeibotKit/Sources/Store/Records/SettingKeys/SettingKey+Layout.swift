import Core
import Foundation
import GRDB

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

public extension SettingKey where Value == Set<String> {
    static var reviewSeenReports: Self {
        Self(
            .reviewSeenReports,
            default: [],
            decode: { text in
                Set(text.split(separator: ",").map(String.init))
            },
            encode: { keys in
                keys.isEmpty ? nil : keys.sorted().joined(separator: ",")
            }
        )
    }
}

public extension SettingKey where Value == Set<HomeSection> {
    static var homeHiddenSections: Self {
        Self(set: .homeHiddenSections)
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
        Self(set: .closedHints)
    }

    static var closedHiddenLists: Self {
        Self(set: .closedHiddenLists)
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
