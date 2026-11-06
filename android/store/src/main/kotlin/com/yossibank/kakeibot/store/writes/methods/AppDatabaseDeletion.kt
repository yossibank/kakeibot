package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.protocols.storedValue
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.theme
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.Deletion
import java.time.Instant

suspend fun AppDatabase.restore(deletion: Deletion) {
    write {
        for (icon in deletion.icons) {
            iconDao().insert(icon.record())
        }

        for (wallet in deletion.wallets) {
            walletDao().insert(wallet.record())
        }

        for (category in deletion.categories) {
            categoryDao().insert(category.record())
        }

        for (tag in deletion.tags) {
            tagDao().insert(tag.record())
        }

        for (recurring in deletion.recurrings) {
            recurringDao().insert(recurring.record())
        }

        for (template in deletion.templates) {
            templateDao().insert(template.record())
        }

        for (budget in deletion.budgets) {
            budgetDao().insert(budget.record())
        }

        for (valuation in deletion.valuations) {
            valuationDao().insert(valuation.record())
        }

        for (adjustment in deletion.adjustments) {
            adjustmentDao().insert(adjustment.record())
        }

        for (shelfIcon in deletion.shelfIcons) {
            shelfIconDao().insert(shelfIcon.record())
        }

        for (rule in deletion.rewardRules) {
            rewardRuleDao().insert(rule.record())
        }

        for (log in deletion.rewardLogs) {
            rewardLogDao().insert(log.record())
        }

        for (theme in deletion.themes) {
            themeDao().insert(theme.record())
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
