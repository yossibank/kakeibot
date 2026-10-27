import GRDB

enum MigrationV1 {
    static func migrate(_ db: Database) throws {
        try createIcon(db)
        try createWallet(db)
        try createCategory(db)
        try createRecurring(db)
        try createEntry(db)
        try createBudget(db)
        try createRewardRule(db)
        try createRewardLog(db)
        try createRewardGoal(db)
        try createCalendarStamp(db)
        try createNoSpendDay(db)
        try createTheme(db)
        try createSetting(db)
    }
}

extension MigrationV1 {
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

    static let themeColors = [
        "background",
        "surface",
        "text_primary",
        "text_secondary",
        "accent",
        "expense",
        "income"
    ]
}

private extension MigrationV1 {
    static func createIcon(_ db: Database) throws {
        try db.create(table: "icon") { table in
            table.primaryKey("id", .text)
            table.column("emoji", .text)
            table.column("text", .text).check { length($0) <= 3 }
            table.column("color", .text).notNull()
            addTimestamps(to: table)
            table.check(sql: "emoji IS NOT NULL OR text IS NOT NULL")
        }
    }

    static func createWallet(_ db: Database) throws {
        try db.create(table: "wallet") { table in
            table.primaryKey("id", .text)
            table.column("name", .text).notNull()

            table.column("kind", .text)
                .notNull()
                .check { walletKinds.contains($0) }

            table.column("icon_id", .text).notNull().references("icon")
            table.column("initial_balance", .integer).notNull()
            table.column("sort_order", .integer).notNull()
            table.column("archived_at", .text)
            addTimestamps(to: table)
        }
    }

    static func createCategory(_ db: Database) throws {
        try db.create(table: "category") { table in
            table.primaryKey("id", .text)

            table.column("kind", .text)
                .notNull()
                .check { categoryKinds.contains($0) }

            table.column("name", .text).notNull()
            table.column("icon_id", .text).notNull().references("icon")
            table.column("sort_order", .integer).notNull()
            table.column("archived_at", .text)
            addTimestamps(to: table)
        }
    }

    static func createRecurring(_ db: Database) throws {
        try db.create(table: "recurring") { table in
            table.primaryKey("id", .text)
            addMovementColumns(to: table)

            table.column("frequency", .text)
                .notNull()
                .check { frequencies.contains($0) }

            table.column("month", .integer).check { (1...12).contains($0) }

            table.column("day", .integer)
                .notNull()
                .check { (1...31).contains($0) }

            table.column("start_date", .text).notNull()
            table.column("end_date", .text)
            table.column("remind_days_before", .integer).check { $0 >= 0 }
            table.column("generated_until", .text)
            addTimestamps(to: table)
            table.check(sql: "(frequency = 'yearly') = (month IS NOT NULL)")
        }
    }

    static func createEntry(_ db: Database) throws {
        try db.create(table: "entry") { table in
            table.primaryKey("id", .text)
            addMovementColumns(to: table)
            table.column("date", .text).notNull()
            table.column("recurring_id", .text).references("recurring")
            table.column("recurring_date", .text)
            addTimestamps(to: table)
            table.uniqueKey(["recurring_id", "recurring_date"])

            let recurringPair = "(recurring_id IS NULL) = (recurring_date IS NULL)"

            table.check(sql: recurringPair)
        }
    }

    static func createBudget(_ db: Database) throws {
        try db.create(table: "budget") { table in
            table.primaryKey("id", .text)
            table.column("category_id", .text).references("category")
            table.column("from_month", .text).notNull()
            table.column("amount", .integer).check { $0 >= 0 }
            table.uniqueKey(["category_id", "from_month"])
        }

        try db.create(
            index: "budget_whole_month",
            on: "budget",
            columns: ["from_month"],
            options: .unique,
            condition: Column("category_id") == nil
        )
    }

    static func createRewardRule(_ db: Database) throws {
        try db.create(table: "reward_rule") { table in
            table.primaryKey("id", .text)
            table.column("name", .text).notNull()
            table.column("amount", .integer).notNull()
            table.column("icon_id", .text).notNull().references("icon")
            table.column("is_active", .boolean).notNull()
            table.column("sort_order", .integer).notNull()
            addTimestamps(to: table)
        }
    }

    static func createRewardLog(_ db: Database) throws {
        try db.create(table: "reward_log") { table in
            table.primaryKey("id", .text)
            table.column("rule_id", .text).notNull().references("reward_rule")
            table.column("date", .text).notNull()
            table.column("amount", .integer).notNull()
            table.column("created_at", .text).notNull()
            table.uniqueKey(["rule_id", "date"])
        }
    }

    static func createRewardGoal(_ db: Database) throws {
        try db.create(table: "reward_goal") { table in
            table.primaryKey("id", .text)
            table.column("name", .text).notNull()
            table.column("target_amount", .integer).notNull()
            table.column("purchased_at", .text)
            table.column("entry_id", .text).references("entry")
            addTimestamps(to: table)
        }
    }

    static func createCalendarStamp(_ db: Database) throws {
        try db.create(table: "calendar_stamp") { table in
            table.primaryKey("id", .text)
            table.column("date", .text).notNull()
            table.column("icon_id", .text).notNull().references("icon")
            table.column("created_at", .text).notNull()
        }
    }

    static func createNoSpendDay(_ db: Database) throws {
        try db.create(table: "no_spend_day") { table in
            table.primaryKey("date", .text)
            table.column("created_at", .text).notNull()
        }
    }

    static func createTheme(_ db: Database) throws {
        try db.create(table: "theme") { table in
            table.primaryKey("id", .text)
            table.column("name", .text).notNull()

            for color in Self.themeColors {
                table.column(color, .text).notNull()
            }

            table.column("corner_radius", .integer).notNull()
            table.column("font_id", .text).notNull()
            table.column("is_builtin", .boolean).notNull()
            addTimestamps(to: table)
        }
    }

    static func createSetting(_ db: Database) throws {
        try db.create(table: "setting") { table in
            table.primaryKey("key", .text)
                .check { settingKeys.contains($0) }

            table.column("value", .text).notNull()
        }
    }

    static func addMovementColumns(to table: TableDefinition) {
        table.column("type", .text)
            .notNull()
            .check { entryKinds.contains($0) }

        table.column("amount", .integer).notNull().check { $0 >= 1 }
        table.column("category_id", .text).references("category")
        table.column("wallet_id", .text).notNull().references("wallet")
        table.column("to_wallet_id", .text).references("wallet")
        table.column("memo", .text)
        table.check(sql: "(type = 'transfer') = (category_id IS NULL)")
        table.check(sql: "(type = 'transfer') = (to_wallet_id IS NOT NULL)")
        table.check(sql: "to_wallet_id IS NULL OR to_wallet_id <> wallet_id")
    }

    static func addTimestamps(to table: TableDefinition) {
        table.column("created_at", .text).notNull()
        table.column("updated_at", .text).notNull()
    }
}
