package com.yossibank.kakeibot.store.writes.methods

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.concepts.recurring.amount
import com.yossibank.kakeibot.core.concepts.recurring.billingPeriod
import com.yossibank.kakeibot.core.concepts.recurring.isRecorded
import com.yossibank.kakeibot.core.concepts.recurring.occurrence
import com.yossibank.kakeibot.core.concepts.recurring.occurrences
import com.yossibank.kakeibot.core.concepts.recurring.pendingOccurrences
import com.yossibank.kakeibot.core.concepts.recurring.scheduledAmount
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.write
import com.yossibank.kakeibot.store.records.protocols.decoded
import com.yossibank.kakeibot.store.records.rows.EntryRecord
import com.yossibank.kakeibot.store.records.rows.RecurringRecord
import com.yossibank.kakeibot.store.records.rows.entry
import com.yossibank.kakeibot.store.records.rows.record
import com.yossibank.kakeibot.store.records.rows.recurring
import com.yossibank.kakeibot.store.records.values.databaseValue
import com.yossibank.kakeibot.store.writes.types.CardBillChange
import java.time.Instant

suspend fun AppDatabase.generateRecurringEntries(
    through: LocalDate,
    at: Instant,
) {
    write {
        val change = CardBillChange()
        val recurrings = recurringDao().all().map { it.decoded(RecurringRecord::recurring) }

        for (recurring in recurrings) {
            generateEntries(
                of = recurring,
                through = through,
                change = change,
                at = at,
            )
        }

        recalculateCardBills(
            change = change,
            at = at,
        )
    }
}

internal suspend fun AppDatabase.insertEntry(
    of: Recurring,
    on: Recurring.Occurrence,
    at: Instant,
): Entry? {
    val date = on.date

    val exists = entryDao()
        .ofRecurring(
            recurringId = of.id.databaseValue,
            earliest = on.scheduled.adding(days = -40).databaseValue,
            latest = on.scheduled.adding(days = 40).databaseValue,
        )
        .map { it.decoded(EntryRecord::entry) }
        .any {
            of.isRecorded(
                by = it,
                scheduled = on.scheduled,
            )
        }

    val amount = billAmount(
        of = of,
        on = on,
    )

    if (exists || amount <= 0) {
        return null
    }

    val billMonth = billMonth(
        paidBy = of.walletId,
        type = of.type,
        on = date,
        shift = of.billShift,
    )

    val entry = fitCategory(
        Entry(
            type = of.type,
            amount = amount.toInt(),
            date = date,
            categoryId = of.categoryId,
            walletId = of.walletId,
            toWalletId = of.toWalletId,
            memo = of.memo,
            recurringId = of.id,
            recurringDate = on.scheduled,
            billMonth = billMonth,
            createdAt = at,
            updatedAt = at,
        ),
    )

    entryDao().insert(entry.record())

    if (entry.type == Entry.Kind.expense) {
        noSpendDayDao().delete(date.databaseValue)
    }

    saveFee(
        amount = of.fee ?: 0,
        transfer = entry,
        at = at,
    )

    return entry
}

internal suspend fun AppDatabase.billAmount(
    of: Recurring,
    on: Recurring.Occurrence,
): Long {
    if (of.billingPeriod(paidOn = on.date) == null || of.toWalletId == null) {
        return of.scheduledAmount(paidOn = on.date).toLong()
    }

    val entries = billEntries(
        of = of,
        on = on,
    )

    return of.amount(
        paidOn = on.date,
        entries = entries,
    )
}

internal suspend fun AppDatabase.billEntries(
    of: Recurring,
    on: Recurring.Occurrence,
): List<Entry> {
    val period = of.billingPeriod(paidOn = on.date) ?: return emptyList()
    val card = of.toWalletId ?: return emptyList()

    return entryDao()
        .billed(
            card = card.databaseValue,
            start = period.start.databaseValue,
            end = period.endInclusive.databaseValue,
            month = on.scheduled.yearMonth.databaseValue,
        )
        .map { it.decoded(EntryRecord::entry) }
}

internal suspend fun AppDatabase.generateEntries(
    of: Recurring,
    through: LocalDate,
    change: CardBillChange,
    at: Instant,
) {
    val occurrences = if (of.archivedAt ==
        null
    ) {
        of.pendingOccurrences(through = through)
    } else {
        emptyList()
    }

    for (occurrence in occurrences) {
        generateEntry(
            of = of,
            on = occurrence,
            change = change,
            at = at,
        )
    }

    if (of.startDate > through) {
        return
    }

    recurringDao().setGeneratedUntil(
        id = of.id.databaseValue,
        date = through.databaseValue,
    )
}

internal suspend fun AppDatabase.generateEarlierEntries(
    of: Recurring,
    before: LocalDate,
    through: LocalDate,
    change: CardBillChange,
    at: Instant,
) {
    if (of.archivedAt != null || of.startDate >= before) {
        return
    }

    val dayBefore = before.adding(days = -1)
    val last = minOf(dayBefore, through)

    val occurrences = of.occurrences(
        from = of.startDate,
        through = last,
    )

    for (occurrence in occurrences) {
        generateEntry(
            of = of,
            on = occurrence,
            change = change,
            at = at,
        )
    }
}

internal suspend fun AppDatabase.generateEntry(
    of: Recurring,
    on: Recurring.Occurrence,
    change: CardBillChange,
    at: Instant,
): Entry? {
    val entry = insertEntry(
        of = of,
        on = on,
        at = at,
    )

    if (entry != null) {
        change.after += entry

        fetchFee(entry.id)?.let { change.after += it }
    }

    return entry
}
