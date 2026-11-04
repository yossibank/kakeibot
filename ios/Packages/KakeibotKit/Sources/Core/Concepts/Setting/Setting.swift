public struct Setting: Codable, Hashable, Sendable {
    public let key: Key

    public var value: String

    public init(
        key: Key,
        value: String
    ) {
        self.key = key
        self.value = value
    }
}

public extension Setting {
    enum Key: String, CaseIterable, Codable, Sendable {
        case monthStartDay = "month_start_day"
        case monthStartShift = "month_start_shift"
        case budgetCarryoverFrom = "budget_carryover_from"
        case weekStart = "week_start"
        case reminderTime = "reminder_time"
        case themeId = "theme_id"
        case cornerStyle = "corner_style"
        case fontStyle = "font_style"
        case textFontStyle = "text_font_style"
        case textSize = "text_size"
        case rowSpacing = "row_spacing"
        case stampShape = "stamp_shape"
        case tabTitles = "tab_titles"
        case backdrop
        case haptics
        case decorations
        case onboardingCompleted = "onboarding_completed"
        case setupCardClosed = "setup_card_closed"
        case entryOpened = "entry_opened"
        case settingsOpened = "settings_opened"
        case launchScreen = "launch_screen"
        case entryStartsWithAmount = "entry_starts_with_amount"
        case templateOrder = "template_order"
        case homeSections = "home_sections"
        case homeHiddenSections = "home_hidden_sections"
        case categoriesByUse = "categories_by_use"
        case recordsLayout = "records_layout"
        case reviewScale = "review_scale"
        case reviewKind = "review_kind"
        case closedHints = "closed_hints"
        case closedHiddenLists = "closed_hidden_lists"
        case recentSearches = "recent_searches"
        case receiptSavedCount = "receipt_saved_count"
        case receiptGuideHidden = "receipt_guide_hidden"
        case widgetEntry = "widget_entry"
        case feeCategoryId = "fee_category_id"
        case transferOutCategoryId = "transfer_out_category_id"
        case transferInCategoryId = "transfer_in_category_id"
        case backupExportedAt = "backup_exported_at"
        case reviewRequestedVersion = "review_requested_version"
        case whatsNewSeenVersion = "whats_new_seen_version"
    }
}

extension Setting: Identifiable {
    public var id: Key {
        key
    }
}
