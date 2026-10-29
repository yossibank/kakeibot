import Core
import Foundation
import GRDB
import Store
import Testing

extension RecordTests.Sample {
    var tables: RecordTests.Tables {
        RecordTests.Tables(
            icons: [icon],
            shelfIcons: [shelfIcon],
            wallets: [cash, bank, loan],
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

        let shelfIcon = ShelfIcon(
            iconId: icon.id,
            sortOrder: 0,
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

        let loan = Wallet(
            name: "奨学金",
            kind: .loan,
            iconId: icon.id,
            initialBalance: -240_000,
            loanAmount: 300_000,
            sortOrder: 2,
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
            Setting(key: .monthStartDay, value: "25"),
            Setting(key: .weekStart, value: "monday")
        ]

        self.init(
            now: now,
            icon: icon,
            shelfIcon: shelfIcon,
            cash: cash,
            bank: bank,
            loan: loan,
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
            shelfIcon,
            cash,
            bank,
            loan,
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
