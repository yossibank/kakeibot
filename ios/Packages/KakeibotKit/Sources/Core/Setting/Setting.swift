public struct Setting: Hashable, Sendable {
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
        case weekStart = "week_start"
        case reminderTime = "reminder_time"
        case themeId = "theme_id"
        case cornerStyle = "corner_style"
        case fontStyle = "font_style"
        case textFontStyle = "text_font_style"
        case textSize = "text_size"
        case onboardingCompleted = "onboarding_completed"
        case launchScreen = "launch_screen"
        case entryStartsWithAmount = "entry_starts_with_amount"
        case templateOrder = "template_order"
        case categoryMenuOpened = "category_menu_opened"
        case recordsLayout = "records_layout"
        case reviewScale = "review_scale"
        case reviewKind = "review_kind"
        case closedHints = "closed_hints"
        case closedHiddenLists = "closed_hidden_lists"
        case recentSearches = "recent_searches"
    }
}

extension Setting: Identifiable {
    public var id: Key {
        key
    }
}

extension Setting: Codable {}
