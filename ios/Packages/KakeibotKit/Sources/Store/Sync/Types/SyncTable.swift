public enum SyncTable: String, CaseIterable, Sendable {
    case icon
    case wallet
    case category
    case tag
    case theme
    case recurring
    case template
    case entry
    case entryItem = "entry_item"
    case itemName = "item_name"
    case valuation
    case adjustment
    case budget
    case rewardRule = "reward_rule"
    case rewardLog = "reward_log"
    case rewardGoal = "reward_goal"
    case calendarStamp = "calendar_stamp"
    case shelfIcon = "shelf_icon"
    case noSpendDay = "no_spend_day"
    case setting

    struct UniqueKey {
        let columns: [String]
        let matchesNull: Bool
    }

    static let localSettingKeys: Set = [
        "onboarding_completed",
        "setup_card_closed",
        "entry_opened",
        "settings_opened",
        "closed_hints",
        "closed_hidden_lists",
        "recent_searches",
        "widget_entry"
    ]

    var keyColumn: String {
        switch self {
        case .noSpendDay: "date"
        case .setting: "key"
        default: "id"
        }
    }

    var hasUpdatedAt: Bool {
        switch self {
        case .rewardLog, .calendarStamp, .noSpendDay, .setting: false
        default: true
        }
    }

    var uniqueKeys: [UniqueKey] {
        switch self {
        case .entry:
            [
                UniqueKey(columns: ["recurring_id", "recurring_date"], matchesNull: false),
                UniqueKey(columns: ["transfer_id"], matchesNull: false)
            ]

        case .valuation: [UniqueKey(columns: ["wallet_id", "date"], matchesNull: false)]

        case .budget: [UniqueKey(columns: ["category_id", "from_month"], matchesNull: true)]

        case .rewardLog: [UniqueKey(columns: ["rule_id", "date"], matchesNull: false)]

        case .calendarStamp: [UniqueKey(columns: ["date"], matchesNull: false)]

        case .itemName: [UniqueKey(columns: ["store", "raw"], matchesNull: false)]

        default: []
        }
    }
}
