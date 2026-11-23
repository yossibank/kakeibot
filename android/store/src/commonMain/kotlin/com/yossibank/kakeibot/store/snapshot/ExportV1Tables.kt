package com.yossibank.kakeibot.store.snapshot

import com.yossibank.kakeibot.core.concepts.export.v1.ExportV1
import com.yossibank.kakeibot.core.concepts.setting.Setting
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.records.protocols.TableColumn
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
import com.yossibank.kakeibot.store.records.rows.adjustmentTable
import com.yossibank.kakeibot.store.records.rows.budget
import com.yossibank.kakeibot.store.records.rows.budgetTable
import com.yossibank.kakeibot.store.records.rows.calendarStamp
import com.yossibank.kakeibot.store.records.rows.calendarStampTable
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.entryCategory
import com.yossibank.kakeibot.store.records.rows.entryCategoryTable
import com.yossibank.kakeibot.store.records.rows.entryItem
import com.yossibank.kakeibot.store.records.rows.entryItemTable
import com.yossibank.kakeibot.store.records.rows.entryTable
import com.yossibank.kakeibot.store.records.rows.entryTag
import com.yossibank.kakeibot.store.records.rows.entryTagTable
import com.yossibank.kakeibot.store.records.rows.entryTemplate
import com.yossibank.kakeibot.store.records.rows.entryTemplateTable
import com.yossibank.kakeibot.store.records.rows.icon
import com.yossibank.kakeibot.store.records.rows.iconTable
import com.yossibank.kakeibot.store.records.rows.itemName
import com.yossibank.kakeibot.store.records.rows.itemNameTable
import com.yossibank.kakeibot.store.records.rows.noSpendDay
import com.yossibank.kakeibot.store.records.rows.noSpendDayTable
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.rows.recurringTable
import com.yossibank.kakeibot.store.records.rows.rewardGoal
import com.yossibank.kakeibot.store.records.rows.rewardGoalTable
import com.yossibank.kakeibot.store.records.rows.rewardLog
import com.yossibank.kakeibot.store.records.rows.rewardLogTable
import com.yossibank.kakeibot.store.records.rows.rewardRule
import com.yossibank.kakeibot.store.records.rows.rewardRuleTable
import com.yossibank.kakeibot.store.records.rows.setting
import com.yossibank.kakeibot.store.records.rows.settingTable
import com.yossibank.kakeibot.store.records.rows.shelfIcon
import com.yossibank.kakeibot.store.records.rows.shelfIconTable
import com.yossibank.kakeibot.store.records.rows.theme
import com.yossibank.kakeibot.store.records.rows.themeTable
import com.yossibank.kakeibot.store.records.rows.valuation
import com.yossibank.kakeibot.store.records.rows.valuationTable
import com.yossibank.kakeibot.store.records.rows.wallet
import com.yossibank.kakeibot.store.records.rows.walletTable

internal suspend fun AppDatabase.fetchTables(): ExportV1.Tables {
    val knownKeys = Setting.Key.entries
        .filter { it != Setting.Key.backupExportedAt }
        .map { it.rawValue }

    return ExportV1.Tables(
        icons = iconTable.all(this),
        shelfIcons = shelfIconTable.all(this),
        wallets = walletTable.all(this),
        valuations = valuationTable.all(this),
        adjustments = adjustmentTable.all(this),
        categories = entryCategoryTable.all(this),
        tags = entryTagTable.all(this),
        entries = entryTable.all(this),
        entryItems = entryItemTable.all(this),
        itemNames = itemNameTable.all(this),
        templates = entryTemplateTable.all(this),
        budgets = budgetTable.all(this),
        recurrings = recurringTable.all(this),
        rewardRules = rewardRuleTable.all(this),
        rewardLogs = rewardLogTable.all(this),
        rewardGoals = rewardGoalTable.all(this),
        calendarStamps = calendarStampTable.all(this),
        noSpendDays = noSpendDayTable.all(this),
        themes = themeTable.all(this),
        settings = settingDao().all(knownKeys).map { it.decoded(SettingRecord::setting) },
    )
}

internal suspend fun AppDatabase.deleteAllTables() {
    for (column in columns.asReversed()) {
        column.table.deleteAll(this)
    }
}

internal suspend fun ExportV1.Tables.insert(into: AppDatabase) {
    for (column in columns) {
        column.insert(
            owner = this,
            into = into,
        )
    }
}

private val columns: List<TableColumn<ExportV1.Tables, *>> = listOf(
    TableColumn(iconTable) { it.icons },
    TableColumn(shelfIconTable) { it.shelfIcons },
    TableColumn(walletTable) { it.wallets },
    TableColumn(valuationTable) { it.valuations },
    TableColumn(adjustmentTable) { it.adjustments },
    TableColumn(entryCategoryTable) { it.categories },
    TableColumn(entryTagTable) { it.tags },
    TableColumn(recurringTable) { it.recurrings },
    TableColumn(entryTemplateTable) { it.templates },
    TableColumn(entryTable) { tables -> tables.entries.sortedBy { it.transferId != null } },
    TableColumn(entryItemTable) { it.entryItems },
    TableColumn(itemNameTable) { it.itemNames },
    TableColumn(budgetTable) { it.budgets },
    TableColumn(rewardRuleTable) { it.rewardRules },
    TableColumn(rewardLogTable) { it.rewardLogs },
    TableColumn(rewardGoalTable) { it.rewardGoals },
    TableColumn(calendarStampTable) { it.calendarStamps },
    TableColumn(noSpendDayTable) { it.noSpendDays },
    TableColumn(themeTable) { it.themes },
    TableColumn(settingTable) { it.settings },
)
