package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.TableColumn
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.adjustmentTable
import com.yossibank.kakeibot.store.records.rows.budgetTable
import com.yossibank.kakeibot.store.records.rows.calendarStampTable
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.entryCategoryTable
import com.yossibank.kakeibot.store.records.rows.entryItemTable
import com.yossibank.kakeibot.store.records.rows.entryTable
import com.yossibank.kakeibot.store.records.rows.entryTagTable
import com.yossibank.kakeibot.store.records.rows.entryTemplateTable
import com.yossibank.kakeibot.store.records.rows.iconTable
import com.yossibank.kakeibot.store.records.rows.itemNameTable
import com.yossibank.kakeibot.store.records.rows.noSpendDayTable
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurringTable
import com.yossibank.kakeibot.store.records.rows.rewardGoalTable
import com.yossibank.kakeibot.store.records.rows.rewardLogTable
import com.yossibank.kakeibot.store.records.rows.rewardRuleTable
import com.yossibank.kakeibot.store.records.rows.settingTable
import com.yossibank.kakeibot.store.records.rows.shelfIconTable
import com.yossibank.kakeibot.store.records.rows.themeTable
import com.yossibank.kakeibot.store.records.rows.valuationTable
import com.yossibank.kakeibot.store.records.rows.walletTable
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.theme
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

suspend fun AppDatabase.restore(deletion: Deletion) {
    write {
        for (column in deletionColumns) {
            column.insert(
                owner = deletion,
                into = this@restore,
            )
        }

        for (entry in deletion.entries) {
            if (entryDao().exists(entry.id.databaseValue)) {
                entryDao().update(entry.record())
            }
        }

        deletion.themeChoice?.let { choice ->
            storeSetting(
                key = SettingKey.theme,
                to = choice,
            )
        }
    }
}

internal suspend fun AppDatabase.deleteRecurrings(
    recurrings: List<Recurring>,
    at: Instant,
): Deletion {
    val ids = recurrings.map { it.id.databaseValue }
    val entries = entryDao().ofRecurrings(ids).map { it.decoded(EntryRecord::entry) }

    entryDao().detachRecurrings(
        recurringIds = ids,
        updatedAt = at.storedValue,
    )

    recurringDao().deleteIds(ids)

    return Deletion(
        recurrings = recurrings,
        entries = entries,
    )
}

internal suspend fun AppDatabase.detachRewardGoals(
    from: List<Identifier<Entry>>,
    at: Instant,
) {
    rewardGoalDao().detach(
        entryIds = from.map { it.databaseValue },
        updatedAt = at.storedValue,
    )
}

private val deletionColumns: List<TableColumn<Deletion, *>> = listOf(
    TableColumn(iconTable) { it.icons },
    TableColumn(walletTable) { it.wallets },
    TableColumn(entryCategoryTable) { it.categories },
    TableColumn(entryTagTable) { it.tags },
    TableColumn(recurringTable) { it.recurrings },
    TableColumn(entryTemplateTable) { it.templates },
    TableColumn(budgetTable) { it.budgets },
    TableColumn(valuationTable) { it.valuations },
    TableColumn(adjustmentTable) { it.adjustments },
    TableColumn(shelfIconTable) { it.shelfIcons },
    TableColumn(rewardRuleTable) { it.rewardRules },
    TableColumn(rewardLogTable) { it.rewardLogs },
    TableColumn(themeTable) { it.themes },
)
