package com.yossibank.kakeibot.store.snapshot

import com.yossibank.kakeibot.core.concepts.export.v1.ExportV1
import com.yossibank.kakeibot.core.concepts.setting.Setting
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.AdjustmentRecord
import com.yossibank.kakeibot.store.records.rows.BudgetRecord
import com.yossibank.kakeibot.store.records.rows.CalendarStampRecord
import com.yossibank.kakeibot.store.records.rows.EntryCategoryRecord
import com.yossibank.kakeibot.store.records.rows.EntryItemRecord
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.EntryTagRecord
import com.yossibank.kakeibot.store.records.rows.EntryTemplateRecord
import com.yossibank.kakeibot.store.records.rows.IconRecord
import com.yossibank.kakeibot.store.records.rows.ItemNameRecord
import com.yossibank.kakeibot.store.records.rows.NoSpendDayRecord
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.RewardGoalRecord
import com.yossibank.kakeibot.store.records.rows.RewardLogRecord
import com.yossibank.kakeibot.store.records.rows.RewardRuleRecord
import com.yossibank.kakeibot.store.records.rows.SettingRecord
import com.yossibank.kakeibot.store.records.rows.ShelfIconRecord
import com.yossibank.kakeibot.store.records.rows.ThemeRecord
import com.yossibank.kakeibot.store.records.rows.ValuationRecord
import com.yossibank.kakeibot.store.records.rows.WalletRecord
import com.yossibank.kakeibot.store.records.rows.adjustment
import com.yossibank.kakeibot.store.records.rows.budget
import com.yossibank.kakeibot.store.records.rows.calendarStamp
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.entryCategory
import com.yossibank.kakeibot.store.records.rows.entryItem
import com.yossibank.kakeibot.store.records.rows.entryTag
import com.yossibank.kakeibot.store.records.rows.entryTemplate
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.itemName
import com.yossibank.kakeibot.store.records.rows.noSpendDay
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.rows.rewardGoal
import com.yossibank.kakeibot.store.records.rows.rewardLog
import com.yossibank.kakeibot.store.records.rows.rewardRule
import com.yossibank.kakeibot.store.records.rows.setting
import com.yossibank.kakeibot.store.records.rows.shelfIcon
import com.yossibank.kakeibot.store.records.rows.theme
import com.yossibank.kakeibot.store.records.rows.valuation
import com.yossibank.kakeibot.store.records.rows.wallet

internal suspend fun AppDatabase.fetchTables(): ExportV1.Tables {
    val knownKeys = Setting.Key.entries
        .filter { it != Setting.Key.backupExportedAt }
        .map { it.rawValue }

    return ExportV1.Tables(
        icons = iconDao().all().map { it.decoded(IconRecord::icon) },
        shelfIcons = shelfIconDao().all().map { it.decoded(ShelfIconRecord::shelfIcon) },
        wallets = walletDao().all().map { it.decoded(WalletRecord::wallet) },
        valuations = valuationDao().all().map { it.decoded(ValuationRecord::valuation) },
        adjustments = adjustmentDao().all().map { it.decoded(AdjustmentRecord::adjustment) },
        categories = categoryDao().all().map { it.decoded(EntryCategoryRecord::entryCategory) },
        tags = tagDao().all().map { it.decoded(EntryTagRecord::entryTag) },
        entries = entryDao().all().map { it.decoded(EntryRecord::entry) },
        entryItems = entryItemDao().all().map { it.decoded(EntryItemRecord::entryItem) },
        itemNames = itemNameDao().all().map { it.decoded(ItemNameRecord::itemName) },
        templates = templateDao().all().map { it.decoded(EntryTemplateRecord::entryTemplate) },
        budgets = budgetDao().all().map { it.decoded(BudgetRecord::budget) },
        recurrings = recurringDao().all().map { it.decoded(RecurringRecord::recurring) },
        rewardRules = rewardRuleDao().all().map { it.decoded(RewardRuleRecord::rewardRule) },
        rewardLogs = rewardLogDao().all().map { it.decoded(RewardLogRecord::rewardLog) },
        rewardGoals = rewardGoalDao().all().map { it.decoded(RewardGoalRecord::rewardGoal) },
        calendarStamps = calendarStampDao().all().map { it.decoded(CalendarStampRecord::calendarStamp) },
        noSpendDays = noSpendDayDao().all().map { it.decoded(NoSpendDayRecord::noSpendDay) },
        themes = themeDao().all().map { it.decoded(ThemeRecord::theme) },
        settings = settingDao().all(knownKeys).map { it.decoded(SettingRecord::setting) },
    )
}

internal suspend fun AppDatabase.deleteAllTables() {
    settingDao().deleteAll()
    themeDao().deleteAll()
    noSpendDayDao().deleteAll()
    calendarStampDao().deleteAll()
    rewardGoalDao().deleteAll()
    rewardLogDao().deleteAll()
    rewardRuleDao().deleteAll()
    budgetDao().deleteAll()
    itemNameDao().deleteAll()
    entryItemDao().deleteAll()
    entryDao().deleteAll()
    templateDao().deleteAll()
    recurringDao().deleteAll()
    tagDao().deleteAll()
    categoryDao().deleteAll()
    adjustmentDao().deleteAll()
    valuationDao().deleteAll()
    walletDao().deleteAll()
    shelfIconDao().deleteAll()
    iconDao().deleteAll()
}

internal suspend fun ExportV1.Tables.insert(into: AppDatabase) {
    for (icon in icons) {
        into.iconDao().insert(icon.record())
    }

    for (shelfIcon in shelfIcons) {
        into.shelfIconDao().insert(shelfIcon.record())
    }

    for (wallet in wallets) {
        into.walletDao().insert(wallet.record())
    }

    for (valuation in valuations) {
        into.valuationDao().insert(valuation.record())
    }

    for (adjustment in adjustments) {
        into.adjustmentDao().insert(adjustment.record())
    }

    for (category in categories) {
        into.categoryDao().insert(category.record())
    }

    for (tag in tags) {
        into.tagDao().insert(tag.record())
    }

    for (recurring in recurrings) {
        into.recurringDao().insert(recurring.record())
    }

    for (template in templates) {
        into.templateDao().insert(template.record())
    }

    for (entry in entries.filter { it.transferId == null } + entries.filter { it.transferId != null }) {
        into.entryDao().insert(entry.record())
    }

    for (entryItem in entryItems) {
        into.entryItemDao().insert(entryItem.record())
    }

    for (itemName in itemNames) {
        into.itemNameDao().insert(itemName.record())
    }

    for (budget in budgets) {
        into.budgetDao().insert(budget.record())
    }

    for (rewardRule in rewardRules) {
        into.rewardRuleDao().insert(rewardRule.record())
    }

    for (rewardLog in rewardLogs) {
        into.rewardLogDao().insert(rewardLog.record())
    }

    for (rewardGoal in rewardGoals) {
        into.rewardGoalDao().insert(rewardGoal.record())
    }

    for (calendarStamp in calendarStamps) {
        into.calendarStampDao().insert(calendarStamp.record())
    }

    for (noSpendDay in noSpendDays) {
        into.noSpendDayDao().insert(noSpendDay.record())
    }

    for (theme in themes) {
        into.themeDao().insert(theme.record())
    }

    for (setting in settings) {
        into.settingDao().insert(setting.record())
    }
}
