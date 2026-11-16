package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.EntryItem
import com.yossibank.kakeibot.core.concepts.entry.NoSpendDay
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.values.databaseValue
import java.time.Instant

suspend fun AppDatabase.restoreEntry(
    entry: Entry,
    fee: Entry? = null,
    items: List<EntryItem>? = null,
    restoringNoSpend: List<NoSpendDay> = emptyList(),
    at: Instant = Instant.now(),
) {
    write {
        val restored = listOfNotNull(entry, fee)

        val change = CardBillChange(
            before = existingRows(restored),
            after = restored,
        )

        restore(
            entries = listOf(entry),
            at = at,
        )

        restoreItems(
            items = items,
            of = listOf(entry.id),
        )

        entryDao().deleteFees(
            transferId = entry.id.databaseValue,
            keptId = fee?.id?.databaseValue,
        )

        if (fee != null) {
            restore(
                entries = listOf(fee),
                at = at,
            )
        }

        restoreNoSpendDays(restoringNoSpend)

        recalculateCardBills(
            change = change,
            at = at,
        )
    }
}

suspend fun AppDatabase.restoreEntries(
    entries: List<Entry>,
    items: List<EntryItem>? = null,
    at: Instant = Instant.now(),
) {
    write {
        val change = CardBillChange(
            before = existingRows(entries),
            after = entries,
        )

        restore(
            entries = entries,
            at = at,
        )

        restoreItems(
            items = items,
            of = entries.map { it.id },
        )

        recalculateCardBills(
            change = change,
            at = at,
        )
    }
}

internal suspend fun AppDatabase.restoreNoSpendDays(days: List<NoSpendDay>) {
    for (day in days) {
        if (entryDao().countExpenses(day.date.databaseValue) == 0) {
            noSpendDayDao().save(day.record())
        }
    }
}

private suspend fun AppDatabase.restore(
    entries: List<Entry>,
    at: Instant,
) {
    val ordered = entries.filter { it.transferId == null } + entries.filter { it.transferId != null }

    for (original in ordered) {
        removeRecordedDuplicates(original)

        val templateId = original.templateId?.takeIf { templateDao().exists(it.databaseValue) }
        val transferId = original.transferId?.takeIf { entryDao().exists(it.databaseValue) }

        val entry = original.copy(
            templateId = templateId,
            transferId = transferId,
        )

        val existing = findEntry(entry.id)

        entryDao().save(entry.record())

        if (existing != null && (existing.walletId != entry.walletId || existing.toWalletId != entry.toWalletId)) {
            touchItems(
                of = listOf(entry.id),
                at = at,
            )
        }

        if (entry.type == Entry.Kind.expense) {
            clearNoSpendDay(entry.date)
        }
    }
}

private suspend fun AppDatabase.removeRecordedDuplicates(entry: Entry) {
    val sameRecurrence = sameRecurrence(entry) ?: return
    val ids = sameRecurrence.filter { it.id != entry.id }.map { it.id.databaseValue }

    entryDao().deleteFees(ids)
    entryDao().deleteIds(ids)
}
