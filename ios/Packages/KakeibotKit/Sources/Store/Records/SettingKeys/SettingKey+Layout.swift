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
