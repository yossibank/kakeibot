package com.yossibank.kakeibot.store.queries.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.notification.NotificationPlan
import com.yossibank.kakeibot.core.concepts.notification.ReminderTime
import com.yossibank.kakeibot.core.concepts.recurring.CardBill
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.observation
import com.yossibank.kakeibot.store.database.read
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.NotificationInput
import com.yossibank.kakeibot.store.queries.types.entryListJoin
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.NoSpendDayRecord
import com.yossibank.kakeibot.store.records.rows.noSpendDay
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.reminderTime
import com.yossibank.kakeibot.store.records.values.databaseValue
import kotlinx.coroutines.flow.Flow

fun AppDatabase.notificationInputUpdates(from: LocalDate): Flow<NotificationInput> = entryListJoin(
    part = observation(
        "no_spend_day",
        "recurring",
        "setting",
    ) {
        fetchNotificationPart(from)
    },
) { list, part ->
    part.input(list)
}

suspend fun AppDatabase.notificationInput(from: LocalDate): NotificationInput = read {
    val list = fetchEntryList(includesItems = false)
    val part = fetchNotificationPart(from)

    part.input(list)
}

private data class NotificationPart(
    val start: LocalDate,
    val markedDates: List<LocalDate>,
    val recurrings: List<Recurring>,
    val reminderTime: ReminderTime?,
) {
    fun input(list: EntryList): NotificationInput {
        val entryDates = list.days.map { it.date }.filter { it >= start }
        val recordedDates = (entryDates + markedDates).toSet()
        val names = list.categories.mapValues { it.value.name }

        return NotificationInput(
            recordedDates = recordedDates,
            recurrings = recurrings,
            reminderTime = reminderTime,
            names = names,
            shortages = shortages(list),
        )
    }

    private fun shortages(list: EntryList): List<NotificationPlan.Shortage> {
        val bills = CardBill.upcoming(
            recurrings = recurrings,
            wallets = list.wallets.values.toList(),
            entries = list.days.flatMap { it.entries },
            valuations = list.valuations,
            adjustments = list.adjustments,
            after = start.adding(days = -1),
        )

        return bills
            .filter { it.shortage > 0 }
            .map { bill ->
                val source = list.wallets[bill.recurring.walletId]

                NotificationPlan.Shortage(
                    recurringId = bill.recurring.id,
                    date = bill.date,
                    walletName = source?.name ?: "口座",
                    amount = bill.shortage,
                )
            }
    }
}

private suspend fun AppDatabase.fetchNotificationPart(start: LocalDate): NotificationPart {
    val markedDates = noSpendDayDao()
        .since(start.databaseValue)
        .map { it.decoded(NoSpendDayRecord::noSpendDay).date }

    return NotificationPart(
        start = start,
        markedDates = markedDates,
        recurrings = fetchRecurrings(),
        reminderTime = fetchSetting(SettingKey.reminderTime),
    )
}
