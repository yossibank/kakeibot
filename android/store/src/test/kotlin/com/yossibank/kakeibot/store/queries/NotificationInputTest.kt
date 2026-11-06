package com.yossibank.kakeibot.store.queries

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryDraft
import com.yossibank.kakeibot.core.concepts.notification.ReminderTime
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertDefaultsIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryOptions
import com.yossibank.kakeibot.store.queries.methods.notificationInput
import com.yossibank.kakeibot.store.queries.methods.notificationInputUpdates
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.reminderTime
import com.yossibank.kakeibot.store.support.insertCardBill
import com.yossibank.kakeibot.store.writes.methods.markNoSpendDay
import com.yossibank.kakeibot.store.writes.methods.saveEntry
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.flow.produceIn
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class NotificationInputTest {
    @Test
    fun collectsRecordedDatesFromStart() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val before = assertNotNull(LocalDate.parse("2026-10-16"))
        val today = assertNotNull(LocalDate.parse("2026-10-17"))
        val marked = assertNotNull(LocalDate.parse("2026-10-18"))
        val time = assertNotNull(ReminderTime.parse("21:00"))

        val dates = listOf(
            before,
            today,
            today,
        )

        for (date in dates) {
            database.saveEntry(
                EntryDraft(
                    type = Entry.Kind.expense,
                    amount = 500,
                    date = date,
                    categoryId = options.expenseCategories[0].id,
                    walletId = options.wallets[0].id,
                ),
                at = now,
            )
        }

        database.markNoSpendDay(
            date = marked,
            at = now,
        )

        database.setSetting(
            key = SettingKey.reminderTime,
            to = time,
        )

        val input = database.notificationInput(from = today)
        val food = options.expenseCategories[0]

        assertEquals(
            setOf(
                today,
                marked,
            ),
            input.recordedDates,
        )
        assertEquals(time, input.reminderTime)
        assertEquals(food.name, input.names[food.id])
        assertTrue(input.recurrings.isEmpty())

        database.close()
    }

    @Test
    fun publishesSameInputAsOneRead() = runTest {
        val database = AppDatabase.inMemory()
        val now = Instant.ofEpochSecond(1_791_000_000)
        database.insertDefaultsIfEmpty(now)
        val options = database.entryOptions()
        val bill = database.insertCardBill(now)
        val card = assertNotNull(bill.toWalletId)
        val used = assertNotNull(LocalDate.parse("2026-10-10"))
        val today = assertNotNull(LocalDate.parse("2026-10-17"))
        val marked = assertNotNull(LocalDate.parse("2026-10-18"))
        val time = assertNotNull(ReminderTime.parse("21:00"))

        database.saveEntry(
            EntryDraft(
                type = Entry.Kind.expense,
                amount = 5000,
                date = used,
                categoryId = options.expenseCategories[0].id,
                walletId = card,
            ),
            at = now,
        )

        database.markNoSpendDay(
            date = marked,
            at = now,
        )

        database.setSetting(
            key = SettingKey.reminderTime,
            to = time,
        )

        val updates = database.notificationInputUpdates(from = today).produceIn(backgroundScope)
        val first = updates.receive()
        val read = database.notificationInput(from = today)

        assertEquals(read, first)
        assertEquals(setOf(marked), read.recordedDates)
        assertEquals(listOf(5000L), read.shortages.map { it.amount })

        database.saveEntry(
            EntryDraft(
                type = Entry.Kind.expense,
                amount = 800,
                date = today,
                categoryId = options.expenseCategories[0].id,
                walletId = options.wallets[0].id,
            ),
            at = now,
        )

        val next = updates.receive()
        val reread = database.notificationInput(from = today)

        assertEquals(reread, next)
        assertEquals(
            setOf(
                today,
                marked,
            ),
            next.recordedDates,
        )

        database.close()
    }
}
