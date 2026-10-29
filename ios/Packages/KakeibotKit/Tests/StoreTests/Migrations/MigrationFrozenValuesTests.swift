@testable import Store
import Testing

struct MigrationFrozenValuesTests {
    private static let hint = Comment(rawValue: "古いマイグレーションの値は変えない")

    @Test
    func walletKindsStayFrozen() {
        #expect(MigrationV1.walletKinds == Self.walletKinds, Self.hint)
        #expect(MigrationV15.walletKinds == Self.walletKinds, Self.hint)
    }

    @Test
    func categoryKindsStayFrozen() {
        #expect(MigrationV1.categoryKinds == Self.categoryKinds, Self.hint)
    }

    @Test
    func frequenciesStayFrozen() {
        #expect(MigrationV1.frequencies == Self.frequencies, Self.hint)
        #expect(MigrationV13.frequencies == Self.frequencies, Self.hint)
    }

    @Test
    func entryKindsStayFrozen() {
        #expect(MigrationV1.entryKinds == Self.entryKinds, Self.hint)
        #expect(MigrationV13.entryKinds == Self.entryKinds, Self.hint)
    }

    @Test
    func settingKeysStayFrozen() {
        #expect(MigrationV1.settingKeys == Self.settingKeys, Self.hint)
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
}
