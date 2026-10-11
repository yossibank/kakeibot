import Core
import Foundation
import GRDB
import Store
import Testing

struct RecordTests {
    @Test
    func roundTripsEveryTable() throws {
        let database = try AppDatabase.inMemory()
        let sample = try Sample()

        try database.writer.write { try sample.insert(into: $0) }
        let stored = try database.writer.read { try Tables(fetchingFrom: $0) }

        #expect(stored == sample.tables)
    }

    @Test
    func storesValuesAsText() throws {
        let database = try AppDatabase.inMemory()
        let sample = try Sample()

        try database.writer.write { try sample.insert(into: $0) }
        let row = try database.writer.read { try Row.fetchOne($0, sql: Self.expenseQuery) }

        #expect(row?["id"] == sample.expense.id.description)
        #expect(row?["type"] == "expense")
        #expect(row?["date"] == "2026-02-27")
        #expect(row?["created_at"] == "2026-10-03T04:00:00Z")
    }

    @Test
    func acceptsValidEntry() throws {
        let database = try AppDatabase.inMemory()
        let sample = try Sample()

        let entry = sample.entry(
            type: .expense,
            categoryId: sample.category.id,
            toWalletId: nil
        )

        try database.writer.write { try sample.insert(into: $0) }
        try database.writer.write { try entry.insert($0) }
        let count = try database.writer.read { try Entry.fetchCount($0) }

        #expect(count == 3)
    }

    @Test(arguments: InvalidRow.allCases)
    func rejectsInvalidRow(invalid: InvalidRow) throws {
        let database = try AppDatabase.inMemory()
        let sample = try Sample()

        try database.writer.write { try sample.insert(into: $0) }

        #expect(throws: DatabaseError.self) {
            try database.writer.write { try invalid.record(alongside: sample).insert($0) }
        }
    }
}

extension RecordTests {
    enum InvalidRow: CaseIterable, Sendable {
        case expenseWithoutCategory
        case transferWithCategory
        case transferToSameWallet
        case zeroAmount
        case duplicateRecurringDate
        case unknownWallet
        case secondWholeMonthBudget
        case duplicateRewardLog
        case iconWithoutEmojiOrText
    }

    struct Tables: Equatable {
        let icons: Set<Icon>
        let wallets: Set<Wallet>
        let categories: Set<EntryCategory>
        let recurrings: Set<Recurring>
        let entries: Set<Entry>
        let budgets: Set<Budget>
        let rewardRules: Set<RewardRule>
        let rewardLogs: Set<RewardLog>
        let rewardGoals: Set<RewardGoal>
        let calendarStamps: Set<CalendarStamp>
        let noSpendDays: Set<NoSpendDay>
        let themes: Set<Theme>
        let settings: Set<Setting>
    }

    struct Sample {
        let now: Date
        let icon: Icon
        let cash: Wallet
        let bank: Wallet
        let category: EntryCategory
        let recurring: Recurring
        let expense: Entry
        let transfer: Entry
        let wholeBudget: Budget
        let categoryBudget: Budget
        let rule: RewardRule
        let rewardLog: RewardLog
        let goal: RewardGoal
        let stamp: CalendarStamp
        let noSpendDay: NoSpendDay
        let theme: Theme
        let settings: [Setting]
    }
}

extension RecordTests.InvalidRow {
    func record(alongside sample: RecordTests.Sample) -> any PersistableRecord {
        switch self {
        case .expenseWithoutCategory:
            sample.entry(
                type: .expense,
                categoryId: nil,
                toWalletId: nil
            )
        case .transferWithCategory:
            sample.entry(
                type: .transfer,
                categoryId: sample.category.id,
                toWalletId: sample.cash.id
            )
        case .transferToSameWallet:
            sample.entry(
                type: .transfer,
                categoryId: nil,
                toWalletId: sample.bank.id
            )
        case .zeroAmount:
            sample.entry(
                type: .expense,
                categoryId: sample.category.id,
                toWalletId: nil,
                amount: 0
            )
        case .duplicateRecurringDate:
            sample.entry(
                type: .expense,
                categoryId: sample.category.id,
                toWalletId: nil,
                recurringId: sample.recurring.id,
                recurringDate: sample.expense.recurringDate
            )
        case .unknownWallet:
            sample.entry(
                type: .expense,
                categoryId: sample.category.id,
                toWalletId: nil,
                walletId: Wallet.ID()
            )
        case .secondWholeMonthBudget:
            Budget(
                categoryId: nil,
                fromMonth: sample.wholeBudget.fromMonth,
                amount: 1
            )
        case .duplicateRewardLog:
            RewardLog(
                ruleId: sample.rule.id,
                date: sample.rewardLog.date,
                amount: 1,
                createdAt: sample.now
            )
        case .iconWithoutEmojiOrText:
            Icon(
                emoji: nil,
                text: nil,
                color: "#000000",
                createdAt: sample.now,
                updatedAt: sample.now
            )
        }
    }
}

extension RecordTests.Tables {
    init(fetchingFrom db: Database) throws {
        try self.init(
            icons: Set(Icon.fetchAll(db)),
            wallets: Set(Wallet.fetchAll(db)),
            categories: Set(EntryCategory.fetchAll(db)),
            recurrings: Set(Recurring.fetchAll(db)),
            entries: Set(Entry.fetchAll(db)),
            budgets: Set(Budget.fetchAll(db)),
            rewardRules: Set(RewardRule.fetchAll(db)),
            rewardLogs: Set(RewardLog.fetchAll(db)),
            rewardGoals: Set(RewardGoal.fetchAll(db)),
            calendarStamps: Set(CalendarStamp.fetchAll(db)),
            noSpendDays: Set(NoSpendDay.fetchAll(db)),
            themes: Set(Theme.fetchAll(db)),
            settings: Set(Setting.fetchAll(db))
        )
    }
}

extension RecordTests.Sample {
    var tables: RecordTests.Tables {
        RecordTests.Tables(
            icons: [icon],
            wallets: [cash, bank],
            categories: [category],
            recurrings: [recurring],
            entries: [expense, transfer],
            budgets: [wholeBudget, categoryBudget],
            rewardRules: [rule],
            rewardLogs: [rewardLog],
            rewardGoals: [goal],
            calendarStamps: [stamp],
            noSpendDays: [noSpendDay],
            themes: [theme],
            settings: Set(settings)
        )
    }

    init() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let previousDay = try #require(LocalDate("2026-02-26"))
        let day = try #require(LocalDate("2026-02-27"))
        let nextDay = try #require(LocalDate("2026-02-28"))
        let firstRecurringDay = try #require(LocalDate("2026-01-27"))
        let month = try #require(YearMonth("2026-01"))

        let icon = Icon(
            emoji: "🍙",
            text: nil,
            color: "#FF8800",
            createdAt: now,
            updatedAt: now
        )

        let cash = Wallet(
            name: "財布",
            kind: .cash,
            iconId: icon.id,
            initialBalance: 1000,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )

        let bank = Wallet(
            name: "銀行",
            kind: .bank,
            iconId: icon.id,
            initialBalance: 50000,
            sortOrder: 1,
            createdAt: now,
            updatedAt: now
        )

        let category = EntryCategory(
            kind: .expense,
            name: "食費",
            iconId: icon.id,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )

        let recurring = Recurring(
            type: .expense,
            amount: 980,
            categoryId: category.id,
            walletId: bank.id,
            frequency: .monthly,
            day: 27,
            startDate: firstRecurringDay,
            createdAt: now,
            updatedAt: now
        )

        let expense = Entry(
            type: .expense,
            amount: 980,
            date: day,
            categoryId: category.id,
            walletId: bank.id,
            memo: "動画",
            recurringId: recurring.id,
            recurringDate: day,
            createdAt: now,
            updatedAt: now
        )

        let transfer = Entry(
            type: .transfer,
            amount: 3000,
            date: nextDay,
            categoryId: nil,
            walletId: bank.id,
            toWalletId: cash.id,
            createdAt: now,
            updatedAt: now
        )

        let wholeBudget = Budget(
            categoryId: nil,
            fromMonth: month,
            amount: 100_000
        )

        let categoryBudget = Budget(
            categoryId: category.id,
            fromMonth: month,
            amount: 30000
        )

        let rule = RewardRule(
            name: "自炊した日",
            amount: 300,
            iconId: icon.id,
            isActive: true,
            sortOrder: 0,
            createdAt: now,
            updatedAt: now
        )

        let rewardLog = RewardLog(
            ruleId: rule.id,
            date: day,
            amount: 300,
            createdAt: now
        )

        let goal = RewardGoal(
            name: "新しい靴",
            targetAmount: 8000,
            createdAt: now,
            updatedAt: now
        )

        let stamp = CalendarStamp(
            date: day,
            iconId: icon.id,
            createdAt: now
        )

        let noSpendDay = NoSpendDay(
            date: previousDay,
            createdAt: now
        )

        let theme = Theme(
            name: "標準",
            background: "#FFFFFF",
            surface: "#F5F5F5",
            textPrimary: "#111111",
            textSecondary: "#666666",
            accent: "#FF8800",
            expense: "#D33F49",
            income: "#2E8B57",
            cornerRadius: 12,
            fontId: "system",
            isBuiltin: true,
            createdAt: now,
            updatedAt: now
        )

        let settings = [
            Setting(
                key: .monthStartDay,
                value: "25"
            ),
            Setting(
                key: .weekStart,
                value: "monday"
            )
        ]

        self.init(
            now: now,
            icon: icon,
            cash: cash,
            bank: bank,
            category: category,
            recurring: recurring,
            expense: expense,
            transfer: transfer,
            wholeBudget: wholeBudget,
            categoryBudget: categoryBudget,
            rule: rule,
            rewardLog: rewardLog,
            goal: goal,
            stamp: stamp,
            noSpendDay: noSpendDay,
            theme: theme,
            settings: settings
        )
    }

    func insert(into db: Database) throws {
        let records: [any PersistableRecord] = [
            icon,
            cash,
            bank,
            category,
            recurring,
            expense,
            transfer,
            wholeBudget,
            categoryBudget,
            rule,
            rewardLog,
            goal,
            stamp,
            noSpendDay,
            theme
        ] + settings

        for record in records {
            try record.insert(db)
        }
    }

    func entry(
        type: Entry.Kind,
        categoryId: EntryCategory.ID?,
        toWalletId: Wallet.ID?,
        amount: Int = 500,
        walletId: Wallet.ID? = nil,
        recurringId: Recurring.ID? = nil,
        recurringDate: LocalDate? = nil
    ) -> Entry {
        Entry(
            type: type,
            amount: amount,
            date: expense.date,
            categoryId: categoryId,
            walletId: walletId ?? bank.id,
            toWalletId: toWalletId,
            recurringId: recurringId,
            recurringDate: recurringDate,
            createdAt: now,
            updatedAt: now
        )
    }
}

private extension RecordTests {
    static let expenseQuery = "SELECT * FROM entry WHERE type = 'expense'"
}
