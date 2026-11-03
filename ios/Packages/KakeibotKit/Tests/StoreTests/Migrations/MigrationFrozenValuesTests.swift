import Foundation
@testable import Store
import Testing

struct MigrationFrozenValuesTests {
    private static let hint = Comment(rawValue: "古いマイグレーションの値は変えない")

    @Test
    func walletKindsStayFrozen() {
        #expect(MigrationV001.walletKinds == Self.walletKinds, Self.hint)
        #expect(MigrationV015.walletKinds == Self.walletKinds, Self.hint)
    }

    @Test
    func categoryKindsStayFrozen() {
        #expect(MigrationV001.categoryKinds == Self.categoryKinds, Self.hint)
    }

    @Test
    func frequenciesStayFrozen() {
        #expect(MigrationV001.frequencies == Self.frequencies, Self.hint)
        #expect(MigrationV013.frequencies == Self.frequencies, Self.hint)
    }

    @Test
    func entryKindsStayFrozen() {
        #expect(MigrationV001.entryKinds == Self.entryKinds, Self.hint)
        #expect(MigrationV013.entryKinds == Self.entryKinds, Self.hint)
    }

    @Test
    func settingKeysStayFrozen() {
        #expect(MigrationV001.settingKeys == Self.settingKeys, Self.hint)
    }

    @Test
    func syncTriggersStayFrozen() {
        let tables = MigrationV026.tables.map { table, key in
            "\(table).\(key)"
        }

        let events = MigrationV026.events.map { name, event, row in
            "\(name) \(event) \(row)"
        }

        let localSettingKeys = MigrationV026.localSettingKeys
            .split(separator: ",")
            .map { key in
                key.trimmingCharacters(in: CharacterSet(charactersIn: " '"))
            }

        #expect(tables == Self.syncTables, Self.hint)
        #expect(events == Self.syncEvents, Self.hint)
        #expect(localSettingKeys == Self.localSettingKeys, Self.hint)
        #expect(MigrationV026.recording == Self.syncRecording, Self.hint)
    }
}

extension MigrationFrozenValuesTests {
    static let walletKinds = [
        "cash",
        "bank",
        "card",
        "emoney",
        "point",
        "other",
        "investment",
        "loan"
    ]

    static let categoryKinds = [
        "expense",
        "income"
    ]

    static let frequencies = [
        "monthly",
        "yearly"
    ]

    static let entryKinds = [
        "expense",
        "income",
        "transfer"
    ]

    static let settingKeys = [
        "month_start_day",
        "week_start",
        "reminder_time",
        "theme_id",
        "corner_style",
        "font_style",
        "text_font_style",
        "text_size",
        "onboarding_completed",
        "setup_card_closed",
        "entry_opened",
        "settings_opened",
        "launch_screen",
        "entry_starts_with_amount",
        "template_order",
        "home_sections",
        "home_hidden_sections",
        "categories_by_use",
        "records_layout",
        "review_scale",
        "review_kind",
        "closed_hints",
        "closed_hidden_lists",
        "recent_searches",
        "widget_entry",
        "fee_category_id"
    ]

    static let syncTables = [
        "icon.id",
        "wallet.id",
        "category.id",
        "tag.id",
        "theme.id",
        "recurring.id",
        "template.id",
        "entry.id",
        "valuation.id",
        "budget.id",
        "reward_rule.id",
        "reward_log.id",
        "reward_goal.id",
        "calendar_stamp.id",
        "shelf_icon.id",
        "no_spend_day.date",
        "setting.key"
    ]

    static let syncEvents = [
        "insert INSERT NEW",
        "update UPDATE NEW",
        "delete DELETE OLD"
    ]

    static let localSettingKeys = [
        "onboarding_completed",
        "setup_card_closed",
        "entry_opened",
        "settings_opened",
        "closed_hints",
        "closed_hidden_lists",
        "recent_searches",
        "widget_entry"
    ]

    static let syncRecording = "(SELECT enabled AND NOT applying FROM sync_state)"
}
