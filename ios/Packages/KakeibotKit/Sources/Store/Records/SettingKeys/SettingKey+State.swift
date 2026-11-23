import Core
import Foundation
import GRDB

public extension SettingKey where Value == Int {
    static var receiptSavedCount: Self {
        Self(
            .receiptSavedCount,
            default: 0,
            decode: { Int($0).map { max($0, 0) } },
            encode: { $0 > 0 ? String($0) : nil }
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
        Self(optional: .feeCategoryId)
    }

    static var transferOutCategory: Self {
        Self(optional: .transferOutCategoryId)
    }

    static var transferInCategory: Self {
        Self(optional: .transferInCategoryId)
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
        Self(optional: .reviewRequestedVersion)
    }

    static var whatsNewSeenVersion: Self {
        Self(optional: .whatsNewSeenVersion)
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

    static var receiptGuideHidden: Self {
        Self(flag: .receiptGuideHidden)
    }

    static var storeReviewCardClosed: Self {
        Self(flag: .storeReviewCardClosed)
    }

    static var storeReviewOpened: Self {
        Self(flag: .storeReviewOpened)
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
