package com.yossibank.kakeibot.store.records

import com.yossibank.kakeibot.core.concepts.budget.Budget
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.core.concepts.icon.CalendarStamp
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.reward.RewardGoal
import com.yossibank.kakeibot.core.concepts.reward.RewardLog
import com.yossibank.kakeibot.core.concepts.reward.RewardRule
import com.yossibank.kakeibot.core.concepts.setting.Setting
import com.yossibank.kakeibot.core.concepts.theme.Theme
import com.yossibank.kakeibot.core.concepts.wallet.Wallet
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.rows.budget
import com.yossibank.kakeibot.store.records.rows.calendarStamp
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.entryCategory
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.noSpendDay
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.rows.rewardGoal
import com.yossibank.kakeibot.store.records.rows.rewardLog
import com.yossibank.kakeibot.store.records.rows.rewardRule
import com.yossibank.kakeibot.store.records.rows.setting
import com.yossibank.kakeibot.store.records.rows.shelfIcon
import com.yossibank.kakeibot.store.records.rows.theme
import com.yossibank.kakeibot.store.records.rows.wallet
import java.time.Instant

data class RecordTestTables(
    val icons: Set<Icon?>,
    val shelfIcons: Set<ShelfIcon?>,
    val wallets: Set<Wallet?>,
    val categories: Set<EntryCategory?>,
    val recurrings: Set<Recurring?>,
    val entries: Set<Entry?>,
    val budgets: Set<Budget?>,
    val rewardRules: Set<RewardRule?>,
    val rewardLogs: Set<RewardLog?>,
    val rewardGoals: Set<RewardGoal?>,
    val calendarStamps: Set<CalendarStamp?>,
    val noSpendDays: Set<NoSpendDay?>,
    val themes: Set<Theme?>,
    val settings: Set<Setting?>,
) {
    companion object {
        suspend fun fetchingFrom(database: AppDatabase): RecordTestTables = RecordTestTables(
            icons = database.iconDao().all().map { it.icon() }.toSet(),
            shelfIcons = database.shelfIconDao().all().map { it.shelfIcon() }.toSet(),
            wallets = database.walletDao().all().map { it.wallet() }.toSet(),
            categories = database.categoryDao().all().map { it.entryCategory() }.toSet(),
            recurrings = database.recurringDao().all().map { it.recurring() }.toSet(),
            entries = database.entryDao().all().map { it.entry() }.toSet(),
            budgets = database.budgetDao().all().map { it.budget() }.toSet(),
            rewardRules = database.rewardRuleDao().all().map { it.rewardRule() }.toSet(),
            rewardLogs = database.rewardLogDao().all().map { it.rewardLog() }.toSet(),
            rewardGoals = database.rewardGoalDao().all().map { it.rewardGoal() }.toSet(),
            calendarStamps = database.calendarStampDao().all().map { it.calendarStamp() }.toSet(),
            noSpendDays = database.noSpendDayDao().all().map { it.noSpendDay() }.toSet(),
            themes = database.themeDao().all().map { it.theme() }.toSet(),
            settings = database.settingDao().all().map { it.setting() }.toSet(),
        )
    }
}

class RecordTestSample {
    val now: Instant = Instant.ofEpochSecond(1_791_000_000)

    private val previousDay = date("2026-02-26")
    private val day = date("2026-02-27")
    private val nextDay = date("2026-02-28")
    private val firstRecurringDay = date("2026-01-27")
    private val month = checkNotNull(YearMonth.parse("2026-01"))

    val icon = Icon(
        emoji = "🍙",
        text = null,
        color = "#FF8800",
        createdAt = now,
        updatedAt = now,
    )

    val shelfIcon = ShelfIcon(
        iconId = icon.id,
        sortOrder = 0,
        createdAt = now,
        updatedAt = now,
    )

    val cash = Wallet(
        name = "財布",
        kind = Wallet.Kind.cash,
        iconId = icon.id,
        initialBalance = 1000,
        sortOrder = 0,
        createdAt = now,
        updatedAt = now,
    )

    val bank = Wallet(
        name = "銀行",
        kind = Wallet.Kind.bank,
        iconId = icon.id,
        initialBalance = 50000,
        sortOrder = 1,
        createdAt = now,
        updatedAt = now,
    )

    val loan = Wallet(
        name = "奨学金",
        kind = Wallet.Kind.loan,
        iconId = icon.id,
        initialBalance = -240_000,
        loanAmount = 300_000,
        sortOrder = 2,
        createdAt = now,
        updatedAt = now,
    )

    val category = EntryCategory(
        kind = EntryCategory.Kind.expense,
        name = "食費",
        iconId = icon.id,
        sortOrder = 0,
        createdAt = now,
        updatedAt = now,
    )

    val recurring = Recurring(
        type = Entry.Kind.expense,
        amount = 980,
        categoryId = category.id,
        walletId = bank.id,
        frequency = Recurring.Frequency.monthly,
        day = 27,
        startDate = firstRecurringDay,
        createdAt = now,
        updatedAt = now,
    )

    val expense = Entry(
        type = Entry.Kind.expense,
        amount = 980,
        date = day,
        categoryId = category.id,
        walletId = bank.id,
        memo = "動画",
        recurringId = recurring.id,
        recurringDate = day,
        createdAt = now,
        updatedAt = now,
    )

    val transfer = Entry(
        type = Entry.Kind.transfer,
        amount = 3000,
        date = nextDay,
        categoryId = null,
        walletId = bank.id,
        toWalletId = cash.id,
        createdAt = now,
        updatedAt = now,
    )

    val wholeBudget = Budget(
        categoryId = null,
        fromMonth = month,
        amount = 100_000,
    )

    val categoryBudget = Budget(
        categoryId = category.id,
        fromMonth = month,
        amount = 30000,
    )

    val rule = RewardRule(
        name = "自炊した日",
        amount = 300,
        iconId = icon.id,
        isActive = true,
        sortOrder = 0,
        createdAt = now,
        updatedAt = now,
    )

    val rewardLog = RewardLog(
        ruleId = rule.id,
        date = day,
        amount = 300,
        createdAt = now,
    )

    val goal = RewardGoal(
        name = "新しい靴",
        targetAmount = 8000,
        createdAt = now,
        updatedAt = now,
    )

    val stamp = CalendarStamp(
        date = day,
        iconId = icon.id,
        createdAt = now,
    )

    val noSpendDay = NoSpendDay(
        date = previousDay,
        createdAt = now,
    )

    val theme = Theme(
        name = "標準",
        background = "#FFFFFF",
        surface = "#F5F5F5",
        textPrimary = "#111111",
        textSecondary = "#666666",
        accent = "#FF8800",
        expense = "#D33F49",
        income = "#2E8B57",
        cornerRadius = 12,
        fontId = "system",
        isBuiltin = true,
        createdAt = now,
        updatedAt = now,
    )

    val settings = listOf(
        Setting(
            key = Setting.Key.monthStartDay,
            value = "25",
        ),
        Setting(
            key = Setting.Key.weekStart,
            value = "monday",
        ),
    )

    val tables: RecordTestTables
        get() = RecordTestTables(
            icons = setOf(icon),
            shelfIcons = setOf(shelfIcon),
            wallets = setOf(cash, bank, loan),
            categories = setOf(category),
            recurrings = setOf(recurring),
            entries = setOf(expense, transfer),
            budgets = setOf(wholeBudget, categoryBudget),
            rewardRules = setOf(rule),
            rewardLogs = setOf(rewardLog),
            rewardGoals = setOf(goal),
            calendarStamps = setOf(stamp),
            noSpendDays = setOf(noSpendDay),
            themes = setOf(theme),
            settings = settings.toSet(),
        )

    suspend fun insert(into: AppDatabase) {
        into.write {
            into.iconDao().insert(icon.record())
            into.shelfIconDao().insert(shelfIcon.record())

            for (wallet in listOf(cash, bank, loan)) {
                into.walletDao().insert(wallet.record())
            }

            into.categoryDao().insert(category.record())
            into.recurringDao().insert(recurring.record())
            into.entryDao().insert(expense.record())
            into.entryDao().insert(transfer.record())
            into.budgetDao().insert(wholeBudget.record())
            into.budgetDao().insert(categoryBudget.record())
            into.rewardRuleDao().insert(rule.record())
            into.rewardLogDao().insert(rewardLog.record())
            into.rewardGoalDao().insert(goal.record())
            into.calendarStampDao().insert(stamp.record())
            into.noSpendDayDao().insert(noSpendDay.record())
            into.themeDao().insert(theme.record())

            for (setting in settings) {
                into.settingDao().insert(setting.record())
            }
        }
    }

    fun entry(
        type: Entry.Kind,
        categoryId: Identifier<EntryCategory>?,
        toWalletId: Identifier<Wallet>?,
        amount: Int = 500,
        walletId: Identifier<Wallet>? = null,
        recurringId: Identifier<Recurring>? = null,
        recurringDate: LocalDate? = null,
    ): Entry = Entry(
        type = type,
        amount = amount,
        date = expense.date,
        categoryId = categoryId,
        walletId = walletId ?: bank.id,
        toWalletId = toWalletId,
        recurringId = recurringId,
        recurringDate = recurringDate,
        createdAt = now,
        updatedAt = now,
    )

    private fun date(text: String): LocalDate = checkNotNull(LocalDate.parse(text))
}
